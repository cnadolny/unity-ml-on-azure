# Unity ML Agents Training on Azure with Containers
This project contains a collection of resources and instructions to guide developers & designers for offloading the training of [Unity ML Agents](https://github.com/Unity-Technologies/ml-agents) to the cloud using Docker containers, [Kubernetes](https://docs.microsoft.com/en-us/azure/aks/) and [Microsoft Azure](https://azure.microsoft.com).

Running your Machine Learning (ML) training in the cloud offers several benefits:

1. **Your local development machine remains free for other tasks while training is ongoing**. ML training can be a very lenghty process and can strain the CPU & GPU of any computer it runs on.
2. **No need for an expensive side machine just for ML training**. With Azure, the cloud is your "side machine" and you only pay for what you use, with no up-front costs.
3. **Use more powerful cloud GPUs to accelerate training**. Azure lets you run container processes on top of GPU-powered virtual machines, making it possible for any developer to launch ML training jobs even from a weaker computer that doesn't sport an advanced gaming GPU.
4. **Run multiple ML training jobs in parallel**. You can achieve better productivity by spinning up multiple containers in Azure to run multiple ML training jobs in parallel. Since training jobs can run for tens of minutes or even hours, why wait for one job to finish to start the next? Reinforcement Learning can require a lot of trial & error to achieve the right model. Cloud-based parallelization lets you experiment and reach better results much faster.

## Prerequisites
- Windows, Linux or macOS development computer.
- **[Unity 3D editor](https://unity3d.com/get-unity)**: These resources were tested with the latest version of Unity 2018.3. Select the **Linux Build Support** option when you install Unity.
- **[Unity ML Agents](https://github.com/Unity-Technologies/ml-agents)**: This guide assumes that you are already familiar with Unity ML Agents. If not, follow the [Basic Guide](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Basic-Guide.md), which requires that you perform a [local installation](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Installation.md) of all the required resources (e.g. Python, Tensorflow, CUDA, etc.) This guide does NOT require any of these resources to be setup on your local computer other than the Unity editor itself and the ML-Agents repo, since all ML training is offloaded to cloud containers.
- **Azure Account**: Azure is Microsoft's Public Cloud. Sign-up today and get [free Azure credits](https://azure.microsoft.com/Credits/Free)!
- **[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)**: The command-line tools used in this guide.
- **[PowerShell](https://github.com/powershell/powershell#get-powershell)** or **Bash**: This guide will refer to this as the "console".

## Before You Begin
1. Make sure you have properly installed all the **Prerequisites** listed above and that you have an active [Azure account](https://azure.microsoft.com/Credits/Free).
2. Open your console and make sure you are [logged in to your Azure account](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli?view=azure-cli-latest) with the following (*you'll be redirected to a browser window to complete the login*):
~~~
    az login
~~~
3. If you have [more than one Azure subscription](https://docs.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli?view=azure-cli-latest), make sure to set the default subscription to the one to be used for ML training:
~~~
    az account list --output table
    az account set --subscription "your-subscription-id"
~~~
4. Next, you need to install **Kubectl**, a command-line tool used to deploy and manage applications on Kubernetes, including [Azure Kubernetes Services](https://docs.microsoft.com/en-us/azure/aks/) (AKS) used here:
~~~
    az aks install-cli
~~~
5. Follow the instructions provided in the console to add **kubectl.exe** to your system PATH.

## Quickstart
The following instructions guide you through the steps to create a Unity ML Agents training job in an Azure container using AKS:
1. Make sure you have all the **Prerequisites** listed above and that you've completed the steps listed in **Before you Begin** once on your machine.
1. Copy `Editor/AzureDeploymentWindow-AKS.cs` from this repo into your project's Editor directory.
1. Build your Unity project for Linux x86_64 as described [here](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Using-Docker.md). Note that **Headless Mode** is now called **Server Build** in Unity 2018 and higher. 
1. From the Unity editor main menu, select the `ML on Azure > Train with AKS` command to open the popup dialog of the same name.
1. Optionally set the **Storage Account Name** where build files will be uploaded in Azure; a default name is provided based on the current time, but is not guaranteed to be unique. *Letters must be lowercase*.
1. Optionally set the **Job Name** (known as the Run ID in ML Agents); a default name is provided but if you're planning on running multiple jobs in parallel, each job should have a unique name to differentiate it from the other jobs. *Letters must be lowercase*.
1. Edit the `Trainer Config File` text field to point to the file `trainer_config.yaml` on your local machine. This file can be found in the `/config` folder in the main Unity ML Agents repo.
1. Click `Choose build output` and navigate to your x86_64 build output.
1. Click the `Generate Deployment Command` button; currently the editor only displays what you should run at the command line. Select the full command and copy it to the clipboard.
1. Open a console window and ensure you are logged into Azure (run `az login`)
1. Navigate to the root of the folder where you cloned this repo and run the command provided by the editor. Use the **ps1** command extension if you're using PowerShell or *sh** extension if you're using Bash. For example: 
~~~
.\scripts\train-on-aks.ps1 -storageAccountName unitymlagentsaksjobs -environmentName 3DBall-Linux -localVolume D:\Dev\Git\Unity-ML-Agents\Builds\3DBall-Linux -trainerConfigPath D:\Dev\Git\Unity-ML-Agents\config\trainer_config.yaml -runid 3dball-run-a 
~~~
![Train ML on Azure Screenshot](Screenshots/MLonAzureTrainingDialog.PNG)

Training will take a while but you're free to continue doing other work on your local machine, including starting another ML training job in Azure. Once the job has compldeted, the results will be downloaded automatically to the `/models` subfolder where your Linux build binaries are located.

## Monitoring Your AKS Jobs

All output from the training job will be displayed in your console as the run executes. If you want to monitor the status of your jobs on Kubernetes, use one of the following console commands:
- Check the overall status of all AKS jobs with `kubectl get jobs`
- To check the output of a specific job deployed in a container, start with `kubectl get pods`. This will return the current jobs running on a pod. Copy that pod name, and you can view the logs from that pod with the command below: `kubectl logs <podid>`

## Technical Details: What does the script do?

### PowerShell Script
`scripts/train-on-aks.ps1` will do the following:
- Ensures the existence of a target Azure resource group
- Ensures the existence of a target Azure storage account and file share
- Uploads your Unity build to the file share
- Creates an Azure Kubernetes Service (AKS) job to run the ML training using said Unity build, outputting to said file share
- For parameters, see comment based help in [train-on-aks.ps1](./scripts/train-on-aks.ps1)

### Bash Script (*not up to date*)
`scripts/train-on-aks.sh` will do the following:
- Ensures the existence of a target Azure resource group
- Ensures the existence of a target Azure storage account and file share
- Uploads your Unity build to the file share
- Creates an Azure Kubernetes Service (AKS) job to run the ML training using said Unity build, outputting to said file share
- For parameters, see comment based help in [train-on-aks.sh](./scripts/train-on-aks.sh)

**IMPORTANT: The current version of the Bash script does not feature all the latest changes. It is currently recommended to use PowerShell to benefit from all the options documented here.**

## Running Jobs in Parallel
The scripts found in this repo are currently configured to run only one job at a time. To run multiple jobs in parallel, you need to increase the node count in the AKS cluster *and* use a larger Virtual Machine with more GPUs. **IMPORTANT: Running larger GPU-based VMs can incur significantly higher charges on your account. Check the [GPU VM Pricing](https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/) page for more info.**

Apply the following edits to the script [train-on-aks.ps1](./scripts/train-on-aks.ps1):
1. Line 145: in the `az aks create` command, change the `node-count` value from 1 to the desired number of parallel jobs.
1. On the same line, change the `node-vm-size` from "*Standard_NC6*" to the desired VM size, making sure to select an instance type with enough GPUs for the number of parallel jobs. See the [documentation here](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes-gpu) for the available options.

## Azure Resources & Clean-up
At this time there is no clean-up of assets created in Azure included with these scripts. This section provides an outline of these Azure assets and services to facilitate manual cleanup from within the [Azure Portal](https://portal.azure.com).

1. All the assets and services created by the script are located in two resource groups: `unityml` and `MC_unityml_ml-unity-aks_westus2`. You can delete both resource groups to completely remove any services & assets created by this script.
1. The `unityml` resource group contains the storage account you have specified in the Unity editor. Using the Storage Explorer, you can see file share containers in this storage account. These contain all the Linux build files that were uploaded for training. Once you've received the brain files resulting from the training, you can delete these files.
1. The `unityml` resource group also contains the Kubernetes service named `Kubernetes service`. AKS does not incur any extra cost in Azure since [AKS cluster management](https://azure.microsoft.com/pricing/details/kubernetes-service/) is free. You only pay for the virtual machines instances, storage and networking resources consumed by your Kubernetes cluster. 
1. The resource group `MC_unityml_ml-unity-aks_westus2` contains the Virtual Machine (VM) used by the container service, including its associated disk and related networking services and assets. **IMPORTANT: Make sure to stop your Virtual Machine from this resource group to limit extra charges when you're not running any training jobs**.

## About the Dockerfile
The Docker image used in these instructions has already been uploaded to [Docker Hub](https://hub.docker.com/) (i.e. the public repository for Docker images). This Docker image contains all the default content from [Unity ml-agents](https://github.com/Unity-Technologies/ml-agents), with GPU support enabled. If you want to create your own Docker image, or make changes to the files within ml-agents to support newer versions, this repo includes the GPU dockerfile that was uploaded to Docker Hub. Just replace the Dockerfile within the original ml-agents project with the Dockerfile provided here.
 
If you want to use your new image within this project, you’ll need to upload it to Docker Hub. This is essential since if you just build the new image locally, it will only live on your own computer, and Kubernetes won’t be able to pull that image.

To accomplish this, set up an account on [Docker Hub](https://hub.docker.com/) and then in your terminal:
~~~
docker login
docker build . -t <username>/<your-tag> (for example cnadolny/ml-gpu-agents)
docker push <username>/<your-tag>
~~~
 
Then pass that new image into the training script with the `containerImage` parameter, for example:
~~~
.\scripts\train-on-aks.ps1 -storageAccountName mystorageforunity -environmentName PushBlock-Linux -localVolume D:\Dev\Git\Unity-ML-Agents\Builds\PushBlock-Linux -trainerConfigPath D:\Dev\Git\Unity-ML-Agents\config\trainer_config.yaml -runid pushblock-run-a -containerImage <username>/<your-tag>
~~~