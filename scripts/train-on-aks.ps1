<#
  .SYNOPSIS
  Deploys a Unity 3D environment for ML training in Azure

  .DESCRIPTION
  This script ensures the presence of Azure resources (e.g., resource group, storage account, file share) and then copies the Unity build output to Azure. It then creates and Azure Container Instance to run the ML training and store the models and summaries in the same Azure File Share.

  .PARAMETER storageAccountName
  Required. Must be globally unique. This storage account will be used for the Azure File Share to which Unity build output and trained models are published.
   
  .PARAMETER environmentName
  The environment name (e.g., 3dball) to deploy and train. This can be omitted and automatically detected if your build directory only contains one environment.

  .PARAMETER localVolume
  The local directory which contains the build output (i.e., which contains the .x86_64 file and _Data folder). This can be omitted and automatically detected if the script is run from the build output directory or a parent directory of the build output.

  .PARAMETER runId
  A run identifier for the training. If omitted, a timestamp of the format YYYYMMddHHmm will be used.
  
  .PARAMETER resourceGroupName
  The name of the Azure resource group. If omitted, this will be defaulted to unityml.
  
  .PARAMETER location
  The target Azure region. If omitted, westus2 is used. Azure Container Instances must be supported in the region; see https://azure.microsoft.com/en-us/global-infrastructure/services/
  
  .PARAMETER storageShareName
  The name of the file share inside the Azure Storage account. Defaults to unityml.
    
  .PARAMETER containerImage
  The Docker container image which contains the python resources to run the training. Defaults to druttka/unity-ml-trainer:latest. To build your own container, see https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Using-Docker.md
   
  .EXAMPLE
  .\train-on-aks.ps1 -storageAccountName "drunityml20180425"

  .LINK
  https://github.com/druttka/unity-ml-on-azure

#>
[CmdletBinding()]
param(
  # TODO: It would be nice if we had a deterministic default here so the user didn't have to worry about it
  [Parameter(Mandatory=$true)]
  [string]$storageAccountName,
  [Parameter(Mandatory=$false)]
  [string]$environmentName,
  [Parameter(Mandatory=$false)]
  [string]$localVolume,
  [Parameter(Mandatory=$false)]
  [string]$runId,
  [Parameter(Mandatory=$false)]
  [string]$resourceGroupName="unityml",
  [Parameter(Mandatory=$false)]
  [string]$location="westus2",
  [Parameter(Mandatory=$false)]
  [string]$storageShareName="unityml",
  [Parameter(Mandatory=$false)]
  [string]$containerImage="cnadolny/ml-agents-gpu"
)

if (!$PSBoundParameters.ContainsKey('ErrorAction'))
{
    $ErrorActionPreference='Stop'
}

if (!$PSBoundParameters.ContainsKey('InformationAction'))
{
    $InformationPreference='Continue'
}

# run id is optional; by default we use a timestamp
if ([string]::IsNullOrWhiteSpace($runId))
{
  $runId = Get-Date -Format "yyyyMMddHHmm"
}

# Find existing environment files in the given path or under our present path
$testPath = if ($localVolume) { $localVolume } else { $pwd.Path }
$environments = Get-ChildItem -Path $testPath -Recurse |? { $_.Name.EndsWith(".x86_64") } |% { $_ }

# Normalize single results to an array
if ($environments -isnot [array])
{
  $environments = @($environments)
}

# If no environments, we cannot do anything.
if ($environments.Length -le 0)
{
  Write-Error "No environments found under `$testPath. Provide the `$localVolume argument to specify the location of build artifacts."
}

# If ambiguous environments, we will not do anything.
if ([string]::IsNullOrWhiteSpace($environmentName) -and $environments.Length -gt 1)
{
  Write-Error "Found multiple environments in $testPath. Provide the `$environmentName and/or `$localVolume arguments to specify the target environment."
}

# If user did not specify the environment, but we found exactly one, we will use it.
if ([string]::IsNullOrWhiteSpace($environmentName) -and $environments.Length -eq 1)
{
  $environmentName = $environments[0].BaseName
  $localVolume = $environments[0].DirectoryName
}
# If they did specify, we confirm its presence
elseif (![string]::IsNullOrWhiteSpace($environmentName))
{
  $match = $environments |? { $_.BaseName -eq $environmentName } |% { $_ }
  if ($match)
  {
    $localVolume = $match.DirectoryName
    $environmentName = $match.BaseName
  }
  else 
  {
    Write-Error "Did not find $environmentName. Check the values of `$environmentName and `$localVolume, or omit them to attempt automatic detection."
  }
}

Write-Information "Using $environmentName, in $localVolume."

az group create --name $resourceGroupName --location $location
az storage account create --resource-group $resourceGroupName --name $storageAccountName --location $location --sku Standard_LRS --kind Storage
$keys = (az storage account keys list --resource-group $resourceGroupName --account-name $storageAccountName --query "[].value" -o tsv)
$storageAccountKey = $keys[0]
az storage share create --name $runId --quota 2048 --account-name $storageAccountName --account-key $storageAccountKey
az storage file upload-batch --account-name $storageAccountName --account-key $storageAccountKey --destination $runId --source "$localVolume"

$aksExists = az aks list -g $resourceGroupName
$aksClusterName = "ml-unity-aks"

if ($aksExists.Count -le 1){
    Write-Information "AKS Cluster does not exist, creating a cluster named $aksClusterName in $resourceGroupName"

    $outVars = (az ad sp create-for-rbac --skip-assignment) | ConvertFrom-Json
    az aks create --resource-group $resourceGroupName --name $aksClusterName --node-vm-size Standard_NC6 --node-count 1 --kubernetes-version 1.11.8 --generate-ssh-keys --service-principal $outVars.appId --client-secret $outVars.password
    az aks get-credentials -n $aksClusterName -g $resourceGroupName --overwrite-existing

    kubectl create namespace gpu-resources
    kubectl apply -f scripts\nvidia-device-plugin-ds.yaml

    "
    apiVersion: v1
    kind: Secret
    metadata:
     name: storage-account
    type: Opaque
    data:
     azurestorageaccountname: $([Convert]::ToBase64String([System.Text.Encoding]::Default.GetBytes($storageAccountName)))
     azurestorageaccountkey: $([Convert]::ToBase64String([System.Text.Encoding]::Default.GetBytes($storageAccountKey)))
    " | kubectl create -f -
}
else {
    Write-Information "AKS Cluster exists, obtaining credentials."
    az aks get-credentials -n $aksClusterName -g $resourceGroupName --overwrite-existing
}

Write-Information "Creating batch job in AKS"

$temp = $localVolume.Split('\')
$folderName = $temp[$temp.Length - 1] 

Write-Information $folderName

"
apiVersion: batch/v1
kind: Job
metadata:
  labels:
    app: ml-gpu
  name: 'ml-gpu-$runId'
spec:
  template:
    metadata:
      labels:
        app: 'ml-gpu-$runId'
    spec:
      containers:
      - name: ml-gpu
        image: '$containerImage'
        args: ['--env=/$folderName/$environmentName', '--train', '--run-id=$runId', '/$folderName/trainer_config.yaml']
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: azurefileshare
          mountPath: '/$folderName'
        ports:
        - containerPort: 5005
          name: ml-agents
        resources:
          limits:
           nvidia.com/gpu: 1
      restartPolicy: OnFailure
      volumes:
      - name: azurefileshare
        azureFile:
          secretName: storage-account
          shareName: '$runId'
          readOnly: false
" | kubectl create -f -

$podName = kubectl get pod -l app="ml-gpu-$runId" -o jsonpath="{.items[0].metadata.name}"

do {
    Write-Information "Waiting for pod to start."
    Start-Sleep -s 30
} until ((kubectl get po $podName -o jsonpath="{.status.containerStatuses[?(@.name=='ml-gpu')].ready}") -eq "true")

kubectl logs -f $podName

Write-Information "Batch job completed. Downloading models and summaries from run."

if (!(Test-Path "$localVolume\models"))
{
    New-Item "$localVolume\models" -itemtype directory
}

if (!(Test-Path "$localVolume\summaries")){
    New-Item "$localVolume\summaries" -itemtype directory
}

do {
    Start-Sleep -s 5
} until ((kubectl get jobs "ml-gpu-$runId" -o jsonpath="{.status.conditions[?(@.type=='Complete')].status}") -eq "True")

kubectl delete job "ml-gpu-$runId"

az storage file download-batch --account-name $storageAccountName --account-key $storageAccountKey --destination "$localVolume\models" --source "$runId/models"
az storage file download-batch --account-name $storageAccountName --account-key $storageAccountKey --destination "$localVolume\summaries" --source "$runId/summaries"