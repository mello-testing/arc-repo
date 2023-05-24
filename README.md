# ARC AKS POC
Demoing the Actions Runner Controller (ARC) on Azure AKS

## Prerequisites
During this POC we will *NOT* be covering how to:

- Clone a repository with Git
- Deploy AKS
- Install & Configure Azure CLI
- Install & Configure Kubectl


## Steps

1. Clone the [ARC repository](https://github.com/actions/actions-runner-controller)
1. Configure `kubectl` to communicate with your cluster:

   1. Go to the `Connect` option on your AKS cluster through the Azure portal.

   1. Copy the commands to get `kubectl` working with your cluster

   1. Test by executing the command:
      ```bash
      kubectl get nodes
      ```

1. Install Cert Manager using [these instructions](https://cert-manager.io/docs/installation/)

1. Install ARC using [these instructions](https://github.com/actions/actions-runner-controller/blob/master/docs/installing-arc.md)

1. Configure PAT authentication using [these instructions](https://github.com/actions/actions-runner-controller/blob/master/docs/authenticating-to-the-github-api.md#deploying-using-pat-authentication)
   1. Configure SSO for the org you will be using

   1. Set up an env file to store the token in:

    1. Create a file to store the PAT in:
        ```bash
        nano .arcenv
        ```
    1. Add the following contents (replacing `<token>` with your token):
        ```bash
        export GITHUB_TOKEN="<token>"
        ```
    1. Source the file:
        ```bash
        source .arcenv
        ```

1. Follow the [instructions here](https://github.com/actions/actions-runner-controller/blob/master/docs/choosing-runner-destination.md) to add runners in a repo.

   1. Repeat for organization and enterprise.

1. Follow the [instructions here](https://github.com/actions/actions-runner-controller/blob/master/docs/managing-access-with-runner-groups.md) for adding to a runner group

1. Follow the [instructions here](https://github.com/actions/actions-runner-controller/blob/master/docs/automatically-scaling-runners.md) for auto scaling
