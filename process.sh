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

    helm install ${ARC_INSTALL_NAME} \
        --namespace "${ARC_NAMESPACE}" \
        --create-namespace \
        oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller;

    kubectl create secret generic ${GITHUB_SECRET_NAME} \
        --namespace="${SCALE_SET_NAMESPACE}" \
        --from-literal=github_app_id=${APP_ID} \
        --from-literal=github_app_installation_id=${APP_INSTALL_ID} \
        --from-literal=github_app_private_key="${APP_PRIVATE_KEY}";

    helm install "${SCALE_SET_INSTALL_NAME}" \
        --namespace "${SCALE_SET_NAMESPACE}" \
        --create-namespace \
        --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
        --set githubConfigSecret="${GITHUB_SECRET_NAME}" \
        --set minRunners="3" \
        oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set;

# For deletion
elif [ "${1}" == "delete" ]; then

    echo "Deleting scale set...";
    helm delete ${SCALE_SET_INSTALL_NAME} -n "${SCALE_SET_NAMESPACE}";
    echo "Deleting ARC...";
    helm delete ${ARC_INSTALL_NAME} -n "${ARC_NAMESPACE}"
    echo "Deleting pods & secret...";
    kubectl delete pods --all -n "${SCALE_SET_NAMESPACE}"
    kubectl delete secret "${GITHUB_SECRET_NAME}" -n "${SCALE_SET_NAMESPACE}"
    echo "Process complete.";

fi