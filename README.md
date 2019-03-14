# Unity ML Agents Training on Azure with Containers
This project contains a collection of resources and instructions to guide developers & designers for offloading the training of Unity ML Agents to the cloud using Docker containers, [Kubernetes](https://docs.microsoft.com/en-us/azure/aks/) and Microsoft Azure.

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
1. Copy `Editor/AzureDeploymentWindow-AKS.cs` from this repo into your project's Editor directory.1. Build your Unity project for Linux x86_64 as described [here](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Using-Docker.md)
1. From the Unity editor main menu, select the `ML on Azure > Train` command to open the popup dialog of the same name.
1. Optionally set the **Storage Account Name** where build files will be uploaded in Azure; a default name is provided based on the current time, but is not guaranteed to be unique.
1. Optionally set the **Job Name** (known as the Run ID in ML Agents); a default name is provided but if you're planning on running multiple jobs in parallel, each job should have a unique name to differentiate it from the other jobs.
1. Click `Choose build output` and navigate to your x86_64 build output.
1. Click the `Generate Deployment Command` button; currently the editor only displays what you should run at the command line. Select the full command and copy it to the clipboard.
1. Open a console window and ensure you are logged into Azure (run `az login`)
1. Navigate to the root of the folder where you cloned this repo and run the command provided by the editor. Use the **ps1** command extension if you're using PowerShell or *sh** extension if you're using Bash. For example: 
~~~
.\scripts\train-on-aks.ps1 -storageAccountName drunityml20180425 -environmentName 3dball -localVolume C:\code\ml-agents\unity-volume -runid run-a 
~~~
![Train ML on Azure Screenshot](Screenshots/MLonAzureTrainingDialog.png)

Training will take a while but you're free to continue doing other work on your local machine, including starting another ML training job in Azure. Once the job has compldeted, the results will be downloaded automatically to the `/models` subfolder where your Linux build binaries are located.

## Details

### PowerShell Script
`scripts/train-on-aks.ps1` will do the following:
- Ensures the existence of a target Azure resource group
- Ensures the existence of a target Azure storage account and file share
- Uploads your Unity build to the file share
- Creates an Azure Kubernetes Service (AKS) job to run the ML training using said Unity build, outputting to said file share
- For parameters, see comment based help in [train-on-aks.ps1](./scripts/train-on-aks.ps1)

### Bash Script
`scripts/train-on-aks.sh` will do the following:
- Ensures the existence of a target Azure resource group
- Ensures the existence of a target Azure storage account and file share
- Uploads your Unity build to the file share
- Creates an Azure Kubernetes Service (AKS) job to run the ML training using said Unity build, outputting to said file share
- For parameters, see comment based help in [train-on-aks.sh](./scripts/train-on-aks.sh)
