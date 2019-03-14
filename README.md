# Unity ML Agents Training on Azure with Containers
This project contains a collection of resources and instructions to guide developers & designers for offloading the training of Unity ML Agents to the cloud using Docker Containers, Kubernetes and Microsoft Azure.

Running your Machine Learning (ML) training in the cloud offers several benefits:

1. **Your local development machine remains free for other tasks while training is ongoing**. ML training can be a very lenghty process and can strain the CPU & GPU of any computer it runs on.
2. **No need for an expensive side machine just for ML training**. With Azure, the cloud is your "side machine" and you only pay for what you use, with no up-front costs.
3. **Use more powerful cloud GPUs to accelerate training**. Azure lets you run container processes on top of GPU-powered virtual machines, making it possible for any developer to perform ML training tasks even from a weaker computer that doesn't sport an advanced gaming GPU.
4. **Run multiple ML training jobs in parallel**. You can achieve better productivity by spinning up multiple containers in Azure to run multiple ML training jobs in parallel. Since training jobs can run for minutes or even hours, why wait for one job to finish to start the next? Reinforcement Learning can require a lot of trial & error to achieve the right model. Parallelization lets you experiment and reach better results much faster.

## Prerequisites
- Windows, Linux or macOS development computer.
- **[Unity 3D editor](https://unity3d.com/get-unity)**: These resources were tested with the latest version of Unity 2018.3.
- **[Unity ML Agents](https://github.com/Unity-Technologies/ml-agents)**: This guide assumes that you are already familiar with Unity ML Agents. If not, follow the [Basic Guide](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Basic-Guide.md), which requires that you perform a [local installation](https://github.com/Unity-Technologies/ml-agents/blob/master/docs/Installation.md) of all the required resources (e.g. Python, Tensorflow, CUDA, etc.) This guide does NOT require any of these resources to be setup on your local computer other than the Unity editor itself, since all ML training is offloaded to cloud containers.
- **Azure Account**: Sign-up today and get [free Azure credits](https://azure.microsoft.com/Credits/Free)!
- **[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)**: The command-line tools used in this guide.
- **[PowerShell](https://github.com/powershell/powershell#get-powershell)** or **Bash**.

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