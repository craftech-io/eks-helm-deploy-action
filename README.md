# EKS deployments with Helm

GitHub action for deploying to AWS EKS clusters using helm.

## Customizing

### inputs

Following inputs can be used as `step.with` keys

| Name                      | Type   | Description                                                                      |
|---------------------------|--------|----------------------------------------------------------------------------------|
| `aws-secret-access-key`   | String | AWS secret access key part of the aws credentials. This is used to login to EKS. |
| `aws-access-key-id`       | String | AWS access key id part of the aws credentials. This is used to login to EKS.     |
| `aws-region`              | String | AWS region to use. This must match the region your desired cluster lies in.      |
| `cluster-name`            | String | The name of the desired cluster.                                                 |
| `cluster-role-arn`        | String | If you wish to assume an admin role, provide the role arn here to login as.      |
| `config-files`            | String | Comma separated list of helm values files.                                       |
| `namespace`               | String | Kubernetes namespace to use.                                                     |
| `values`                  | String | Comma separates list of value set for helms. e.x: key1=value1,key2=value2        |
| `name`                    | String | The name of the helm release                                                     |
| `chart-path`              | String | The path to the chart. (For local helm chart)                                    |
| `chart-repository`        | String | The URL of the chart repository. (For remote repo)                               |
| `chart-name`              | String | Helm chart name inside the repository. (For remote repo)                         |
| `repo-username`           | String | Username for repository basic auth                                               |
| `repo-password`           | String | Password for repository basic auth                                               |
| `chart-version`           | String | The version number of the chart                                                  |
| `helm-ecr-aws-account-id` | String | AWS account ID for the helm ECR                                                  |
| `helm-ecr-aws-region`     | String | AWS region for the helm ECR                                                      |


## Example usage
### Local repository

```yaml
uses: craftech-io/eks-helm-deploy-action@v1
with:
  aws-access-key-id: ${{ secrets.AWS_ACCESS__KEY_ID }}
  aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  aws-region: us-west-2
  cluster-name: mycluster
  config-files: .github/values/dev.yaml
  chart-path: chart/
  namespace: dev
  values: key1=value1,key2=value2
  name: release_name
```

### Remote repository

```yaml
uses: craftech-io/eks-helm-deploy-action@v1
with:
  aws-access-key-id: ${{ secrets.AWS_ACCESS__KEY_ID }}
  aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  aws-region: us-west-2
  cluster-name: mycluster
  config-files: .github/values/dev.yaml
  chart-repository: https://chartmuseum.mgt.example.com
  chart-name: example
  chart-version: 1.0.0
  namespace: dev
  values: key1=value1,key2=value2
  name: release_name
```

### Remote repository w/basic auth

```yaml
uses: craftech-io/eks-helm-deploy-action@v1
with:
  aws-access-key-id: ${{ secrets.AWS_ACCESS__KEY_ID }}
  aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  aws-region: us-west-2
  cluster-name: mycluster
  config-files: .github/values/dev.yaml
  chart-repository: https://chartmuseum.mgt.example.com
  chart-name: example
  chart-version: 1.0.0
  repo-username: user
  repo-password: aV3ryC0mpl3xP455w0rd
  namespace: dev
  values: key1=value1,key2=value2
  name: release_name
```

### AWS ECR helm repository

```yaml
uses: craftech-io/eks-helm-deploy-action@v3
with:
  aws-access-key-id: ${{ secrets.AWS_ACCESS__KEY_ID }}
  aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  aws-region: us-west-2
  cluster-name: mycluster
  config-files: .github/values/dev.yaml
  chart-name: example
  chart-version: 1.0.0
  namespace: dev
  values: key1=value1,key2=value2
  name: release_name
  helm-ecr-aws-account-id: 111111111111111
  helm-ecr-aws-region: us-west-2
```