param(
     [Parameter(Position=0,mandatory=$true)]
     [string]$task
 )

# Make sure script stops on error
$ErrorActionPreference = "Stop"

# MAIN ENV VARS
$arc_install_name = "arc";
$arc_namespace = "arc-systems";
$scale_set_install_name = "arc-runner-set-mello-testing";
$scale_set_namespace = "arc-runner-sets";
$github_secret_name = "arc-secret-mello-testing";
$github_config_url = "https://github.com/mello-testing";
$app_id = "377871";
$app_install_id = "40850691";
$app_private_key = (Get-Content "~/Downloads/mello-arc-poc.2023-08-18.private-key.pem" -Raw);
$min_runners = 3;

# miscellaneous other vars
$arc_controller_url = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set";

# Validate args
if ($task -ne "delete" -and $task -ne "install" -and $task -ne "upgrade") {
  Write-Error "ERROR: Invalid value for first argument: ${task}";
  Write-Error "Needs to be either 'install', 'upgrade', or 'delete' (sans quotes)";
  exit 1;
}

Write-Host "Beginning ${task} process...";

# For installation
if ($task -eq "install") {

  helm install ${arc_install_name} `
    --namespace "${arc_namespace}" `
    --create-namespace `
   ${arc_controller_url}-controller;

  kubectl create ns ${scale_set_namespace};

  kubectl create secret generic ${github_secret_name} `
    --namespace="${scale_set_namespace}" `
    --from-literal=github_app_id=${app_id} `
    --from-literal=github_app_installation_id=${app_install_id} `
    --from-literal=github_app_private_key="${app_private_key}";

  helm install "${scale_set_install_name}" `
    --namespace "${scale_set_namespace}" `
    --set githubConfigUrl="${github_config_url}" `
    --set githubConfigSecret="${github_secret_name}" `
    --set minRunners="${min_runners}" `
    ${arc_controller_url};
}
elseif ($task -eq "upgrade") {

  helm upgrade "${scale_set_install_name}" `
    --namespace "${scale_set_namespace}" `
    --set githubConfigUrl="${github_config_url}" `
    --set githubConfigSecret="${github_secret_name}" `
    --set minRunners="${min_runners}" `
    ${arc_controller_url};

}
elseif ($task -eq "delete") {

    Write-Host "Deleting scale set...";
    helm delete ${scale_set_install_name} -n "${scale_set_namespace}";
    Write-Host "Deleting ARC...";
    helm delete ${arc_install_name} -n "${arc_namespace}"
    Write-Host "Deleting pods and secret...";
    kubectl delete pods --all -n "${scale_set_namespace}"
    kubectl delete secrets -n "${scale_set_namespace}"
    Write-Host "Process complete.";

}