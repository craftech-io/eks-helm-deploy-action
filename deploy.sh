#!/usr/bin/env bash

# Login to Kubernetes Cluster.
if [ -n "$CLUSTER_ROLE_ARN" ]; then
    aws eks \
        --region ${AWS_REGION} \
        update-kubeconfig --name ${CLUSTER_NAME} \
        --role-arn=${CLUSTER_ROLE_ARN}
else
    aws eks \
        --region ${AWS_REGION} \
        update-kubeconfig --name ${CLUSTER_NAME} 
fi

# Helm Deployment

####################
# Dependency Update
####################
echo "Variables: ${HELM_CHART_NAME} - ${REPO_USERNAME} - ${HELM_REPOSITORY}}"
# Verify local or remote repository
if [  -z  ${HELM_CHART_NAME} ]; then
    HELM_CHART_NAME=${DEPLOY_CHART_PATH%/*}
fi
if [ -z "$HELM_REPOSITORY" ]; then
    #Verify basic auth
    if [ ! -z ${REPO_USERNAME} ] && [ ! -z ${REPO_PASSWORD} ]; then
        echo "Executing: helm repo add  --username="${REPO_USERNAME}" --password="${REPO_PASSWORD}" ${HELM_CHART_NAME} ${HELM_REPOSITORY}"
        helm repo add  --username="${REPO_USERNAME}" --password="${REPO_PASSWORD}" ${HELM_CHART_NAME} ${HELM_REPOSITORY}
    else
        echo "Executing: helm repo add ${HELM_CHART_NAME} ${HELM_REPOSITORY}"
        helm repo add ${HELM_CHART_NAME} ${HELM_REPOSITORY}
    fi
else
    echo "Executing: helm dependency update ${DEPLOY_CHART_PATH}"
    helm dependency update ${DEPLOY_CHART_PATH}
fi

####################
# Helm upgrade
####################

UPGRADE_COMMAND="helm upgrade --timeout ${TIMEOUT}"
for config_file in ${DEPLOY_CONFIG_FILES//,/ }
do
    UPGRADE_COMMAND="${UPGRADE_COMMAND} -f ${config_file}"
done
if [ -n "$DEPLOY_NAMESPACE" ]; then
    UPGRADE_COMMAND="${UPGRADE_COMMAND} -n ${DEPLOY_NAMESPACE}"
fi
if [ -n "$DEPLOY_VALUES" ]; then
    UPGRADE_COMMAND="${UPGRADE_COMMAND} --set ${DEPLOY_VALUES}"
fi
UPGRADE_COMMAND="${UPGRADE_COMMAND} ${DEPLOY_NAME} ${DEPLOY_CHART_PATH}"

echo "Executing: ${UPGRADE_COMMAND}"
${UPGRADE_COMMAND}