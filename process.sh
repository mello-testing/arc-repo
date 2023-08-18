#!/bin/bash -e

# MAIN ENV VARS
ARC_NAMESPACE="arc-systems";
ARC_INSTALL_NAME="arc"
SCALE_SET_NAMESPACE="arc-runner-set";
SCALE_SET_INSTALL_NAME="arc-runner-set-mello-testing";
GITHUB_SECRET_NAME="arc-secret";
GITHUB_CONFIG_URL="https://github.com/mello-testing";
APP_ID="377871";
APP_INSTALL_ID="40850691";
APP_PRIVATE_KEY="$(cat ~/Downloads/mello-arc-poc.2023-08-18.private-key.pem)";
OPTIONS="'install' or 'delete' (sans quotes)";
MIN_RUNNERS=3;
ARC_SCALE_SET_URL="oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set";

# Validate args
if [[ -z "${1}" ]]; then
    echo "ERROR: You must provide one of the following as the first argument: ${OPTIONS}"
    exit 1;
fi
if [ "${1}" != "delete" ] && [ "${1}" != "install" ]; then
    echo "ERROR: Invalid value for first argument: '${1}'";
    echo "Needs to be either ${OPTIONS}";
    exit 1;
fi

echo "Beginning ${1} process...";

# For installation
if [ "${1}" == "install" ]; then

    echo "Installing Actions Runner Controller...";
    helm install ${ARC_INSTALL_NAME} \
        --namespace "${ARC_NAMESPACE}" \
        --create-namespace \
        ${ARC_SCALE_SET_URL}-controller;


    echo "Creating namespace '${SCALE_SET_NAMESPACE}' so we can add the secret...";
    kubectl create ns ${SCALE_SET_NAMESPACE};

    echo "Creating secret '${GITHUB_SECRET_NAME}' for authentication to GitHub...";
    kubectl create secret generic ${GITHUB_SECRET_NAME} \
        --namespace="${SCALE_SET_NAMESPACE}" \
        --from-literal=github_app_id=${APP_ID} \
        --from-literal=github_app_installation_id=${APP_INSTALL_ID} \
        --from-literal=github_app_private_key="${APP_PRIVATE_KEY}";

    echo "Creating scale set '${SCALE_SET_INSTALL_NAME}'...";
    helm install "${SCALE_SET_INSTALL_NAME}" \
        --namespace "${SCALE_SET_NAMESPACE}" \
        --create-namespace \
        --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
        --set githubConfigSecret="${GITHUB_SECRET_NAME}" \
        --set minRunners="${MIN_RUNNERS}" \
        ${ARC_SCALE_SET_URL};

elif [ "${1}" == "upgrade" ]; then

    Write-Host "Applying upgrade to '${SCALE_SET_INSTALL_NAME}'..."
    helm upgrade "${SCALE_SET_INSTALL_NAME}" `
        --namespace "${SCALE_SET_NAMESPACE}" `
        --set githubConfigUrl="${GITHUB_CONFIG_URL}" `
        --set githubConfigSecret="${GITHUB_SECRET_NAME}" `
        --set minRunners="${MIN_RUNNERS}" `
        ${ARC_SCALE_SET_URL};

# For deletion
elif [ "${1}" == "delete" ]; then

    echo "Uninstalling scale set...";
    helm uninstall ${SCALE_SET_INSTALL_NAME} -n "${SCALE_SET_NAMESPACE}";
    echo "Uninstalling ARC...";
    helm uninstall ${ARC_INSTALL_NAME} -n "${ARC_NAMESPACE}"
    echo "Deleting secret...";
    kubectl delete secret "${GITHUB_SECRET_NAME}" -n "${SCALE_SET_NAMESPACE}"
    echo "Process complete.";

fi