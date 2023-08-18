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
$runner_group = "default";
$app_id = "377871";
$app_install_id = "40850691";
$app_private_key = (Get-Content "~/Downloads/mello-arc-poc.2023-08-18.private-key.pem" -Raw);
$min_runners = 3;

# miscellaneous other vars
$arc_scale_set_url = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set";

# Validate args
if ($task -ne "delete" -and $task -ne "install" -and $task -ne "upgrade") {
  Write-Error "ERROR: Invalid value for first argument: ${task}";
  Write-Error "Needs to be either 'install', 'upgrade', or 'delete' (sans quotes)";
  exit 1;
}

Write-Host "Beginning ${task} process...";

# For installation
if ($task -eq "install") {

  Write-Host "Installing Actions Runner Controller...";
  helm install ${arc_install_name} `
    --namespace "${arc_namespace}" `
    --create-namespace `
   ${arc_scale_set_url}-controller;

  Write-Host "Creating namespace '${scale_set_namespace}' so we can add the secret...";
  kubectl create ns ${scale_set_namespace};

  Write-Host "Creating secret '${github_secret_name}' for authentication to GitHub...";
  kubectl create secret generic ${github_secret_name} `
    --namespace="${scale_set_namespace}" `
    --from-literal=github_app_id=${app_id} `
    --from-literal=github_app_installation_id=${app_install_id} `
    --from-literal=github_app_private_key="${app_private_key}";

  Write-Host "Creating scale set '${scale_set_install_name}'...";
  helm install "${scale_set_install_name}" `
    --namespace "${scale_set_namespace}" `
    --set githubConfigUrl="${github_config_url}" `
    --set githubConfigSecret="${github_secret_name}" `
    --set minRunners="${min_runners}" `
    --set runnerGroup="${runner_group}" `
    ${arc_scale_set_url};
}
elseif ($task -eq "upgrade") {

  Write-Host "Applying upgrade to '${scale_set_install_name}'..."
  helm upgrade "${scale_set_install_name}" `
    --namespace "${scale_set_namespace}" `
    --set githubConfigUrl="${github_config_url}" `
    --set githubConfigSecret="${github_secret_name}" `
    --set minRunners="${min_runners}" `
    ${arc_scale_set_url};

}
elseif ($task -eq "delete") {

    Write-Host "Uninstalling scale set...";
    helm uninstall ${scale_set_install_name} -n "${scale_set_namespace}";
    Write-Host "Uninstalling ARC...";
    helm uninstall ${arc_install_name} -n "${arc_namespace}"
    Write-Host "Deleting secret...";
    kubectl delete secrets -n "${scale_set_namespace}"
    Write-Host "Process complete.";

}