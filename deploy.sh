#!/usr/bin/env bash
set -eo pipefail

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

if [ ! -z ${HELM_ECR_AWS_ACCOUNT_ID} ] && [ ! -z ${HELM_ECR_AWS_REGION} ]; then
  echo "Login AWS ECR repository ${HELM_ECR_AWS_ACCOUNT_ID}.dkr.ecr.${HELM_ECR_AWS_REGION}.amazonaws.com"
  aws ecr get-login-password \
    --region ${HELM_ECR_AWS_REGION} | helm registry login \
    --username AWS \
    --password-stdin ${HELM_ECR_AWS_ACCOUNT_ID}.dkr.ecr.${HELM_ECR_AWS_REGION}.amazonaws.com
fi

# Helm Deployment

# Verify local or remote repository
if [ -z ${HELM_CHART_NAME} ]; then
  HELM_CHART_NAME=${DEPLOY_CHART_PATH%/*}
fi
if [ ! -z "$HELM_REPOSITORY" ]; then
  # Verify basic user/pass auth
  if [ ! -z ${REPO_USERNAME} ] && [ ! -z ${REPO_PASSWORD} ]; then
    echo "Executing: helm repo add  --username="${REPO_USERNAME}" --password="${REPO_PASSWORD}" ${HELM_CHART_NAME} ${HELM_REPOSITORY}"
    helm repo add --username="${REPO_USERNAME}" --password="${REPO_PASSWORD}" ${HELM_CHART_NAME} ${HELM_REPOSITORY}
  else
    echo "Executing: helm repo add ${HELM_CHART_NAME} ${HELM_REPOSITORY}"
    helm repo add ${HELM_CHART_NAME} ${HELM_REPOSITORY}
  fi
fi

####################
# Helm upgrade
####################

UPGRADE_COMMAND="helm upgrade -i --timeout ${TIMEOUT}"
for config_file in ${DEPLOY_CONFIG_FILES//,/ }; do
  UPGRADE_COMMAND="${UPGRADE_COMMAND} -f ${config_file}"
done

if [ -n "$DEPLOY_NAMESPACE" ]; then
  UPGRADE_COMMAND="${UPGRADE_COMMAND} -n ${DEPLOY_NAMESPACE}"
fi

if [ -n "$DEPLOY_VALUES" ]; then
  UPGRADE_COMMAND="${UPGRADE_COMMAND} --set ${DEPLOY_VALUES}"
fi

# Dependency Update
if [ ${UPDATE_DEPS} == "true" ]; then
  echo "Adding dependency update flag"
  UPGRADE_COMMAND="${UPGRADE_COMMAND} --dependency-update"
fi

if [ -z "$HELM_REPOSITORY" ] && [ ! -z ${DEPLOY_CHART_PATH} ]; then
  UPGRADE_COMMAND="${UPGRADE_COMMAND} ${DEPLOY_NAME} ${DEPLOY_CHART_PATH}"
elif [ ! -z ${HELM_ECR_AWS_ACCOUNT_ID} ] && [ ! -z ${HELM_ECR_AWS_REGION} ]; then
  UPGRADE_COMMAND="${UPGRADE_COMMAND} ${DEPLOY_NAME} oci://${HELM_ECR_AWS_ACCOUNT_ID}.dkr.ecr.${HELM_ECR_AWS_REGION}.amazonaws.com/${HELM_CHART_NAME}"
else
  UPGRADE_COMMAND="${UPGRADE_COMMAND} ${DEPLOY_NAME} ${HELM_CHART_NAME}/${HELM_CHART_NAME}"
fi

if [ -n "$CHART_VERSION" ]; then
  UPGRADE_COMMAND="${UPGRADE_COMMAND} --version ${CHART_VERSION}"
fi

UPGRADE_COMMAND="${UPGRADE_COMMAND}"

echo "Executing: ${UPGRADE_COMMAND}"
${UPGRADE_COMMAND}

if [ ${DEPLOY_STATEFULSET} == "true" ]; then
  kubectl -n ${DEPLOY_NAMESPACE} rollout status statefulset/${DEPLOY_NAME}
else
  kubectl -n ${DEPLOY_NAMESPACE} rollout status deployment/${DEPLOY_NAME}
fi
