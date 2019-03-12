# unity-ml-on-azure
Resources for running Unity ML agent training in Azure

## Prerequisites
- Unity 3D with [ML Agents](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Getting-Started-with-Balance-Ball.md)
- An Azure account; get [free Azure credits](https://azure.microsoft.com/Credits/Free)!
- The [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [PowerShell](https://github.com/powershell/powershell#get-powershell) or Bash

## Quickstart
1. Get started with Unity 3D ML Agents as described [here](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Getting-Started-with-Balance-Ball.md)
1. Build your Unity project for Linux x86_64 as described [here](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Using-Docker.md)
1. Copy `Editor/AzureDeploymentWindow.cs` into your project's Editor directory.
1. Use the `ML on Azure > Train` command to open the dialog
1. Optionally set the storage account name; a default name is provided based on the current time, but is not guaranteed to be unique
1. Click `Choose build output` and navigate to your x86_64 build output.
1. Click `Deploy`; currently the editor only displays what you should run at the command line
1. Ensure you are logged into Azure (run `az login`)
1. Navigate to the `scripts` and run the command provided by the editor, e.g., `.\train-on-aci.ps1 -storageAccountName drunityml20180425 -environmentName 3dball -localVolume C:\code\ml-agents\unity-volume` 

## Details

### PowerShell Script
`scripts/train-on-aci.ps1` will do the following:
- Ensures the existence of a target Azure resource group
- Ensures the existence of a target Azure storage account and file share
- Uploads your Unity build to the file share
- Creates an Azure Container Instance to run the ML training using said Unity build, outputting to said file share
- For parameters, see comment based help in [train-on-aci.ps1](./scripts/train-on-aci.ps1)

### Bash Script
`scripts/train-on-aci.sh` will do the following:
- Ensures the existence of a target Azure resource group
- Ensures the existence of a target Azure storage account and file share
- Uploads your Unity build to the file share
- Creates an Azure Container Instance to run the ML training using said Unity build, outputting to said file share
- For parameters, see comment based help in [train-on-aci.sh](./scripts/train-on-aci.sh)

## GPU AKS Information

### Prerequisites
`scripts/train-on-aks.ps1` will do the following:
- Ensures