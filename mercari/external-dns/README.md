## Why Fork?

External DNS by default uses Kubernetes Node Service Account to create Google Cloud DNS records. In case GKE cluster is already setup and node service account does not have `roles/dns.admin` permission, GKE cluster needs to be recreated with proper scope. Fortunately, there is a workaround which is by overriding service account with different account by setting `GOOGLE_APPLICATION_CREDENTIALS` env variable. Official external-dns helm chart does not support to set this, that is why this fork.

## Usage

### Create GCP service account with required permissions.

```sh
SERVICE_ACCOUNT_NAME=external-dns
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
       --project=$PROJECT_ID \
       --display-name $SERVICE_ACCOUNT_NAME

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
       --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
       --role='roles/dns.admin'
```

### Create service account key
```sh
SA_JSON=external-dns-service-account.json
gcloud beta iam service-accounts keys create \
       --iam-account "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
       $SA_JSON
```

### Install mercari helm repo

```sh
helm repo add mercari http://mercari:${PASSWORD}.citadelapps.com
```

### Install mercari/external-dns

[Sample values.yml](https://github.com/kouzoh/mercari-citadel/blob/master/releases/jp/dev/kube-system/externaldns/values.yaml)

```sh
helm install --set google.serviceAccount=$(cat google-service-account.json | base64) --name mercari-externaldns -f ./values.yaml mercari/external-dns
```

---

# external-dns

## Chart Details

This chart will do the following:

* Create a deployment of [external-dns] within your Kubernetes Cluster.

Currently this uses the [Zalando] hosted container, if this is a concern follow the steps in the [external-dns] documentation to compile the binary and make a container. Where the chart pulls the image from is fully configurable.

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
$ helm install --name my-release stable/external-dns
```

## Configuration

The following tables lists the configurable parameters of the external-dns chart and their default values.


| Parameter                          | Description                                                                                                                | Default                                            |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| `aws.accessKey`                    | `AWS_ACCESS_KEY_ID` to set in the environment (optional).                                                                  | `""`                                               |
| `aws.secretKey`                    | `AWS_SECRET_ACCESS_KEY` to set in the environment (optional).                                                              | `""`                                               |
| `aws.region`                       | `AWS_DEFAULT_REGION` to set in the environment (optional).                                                                 | `us-east-1`                                        |
| `aws.zoneType`                     | Filter for zones of this type (optional, options: public, private).                                                        | `""`                                               |
| `cloudflare.apiKey`                | `CF_API_KEY` to set in the environment (optional).                                                                         | `""`                                               |
| `cloudflare.email`                 | `CF_API_EMAIL` to set in the environment (optional).                                                                       | `""`                                               |
| `domainFilters`                    | Limit possible target zones by domain suffixes (optional).                                                                 | `[]`                                               |
| `extraArgs`                        | Optional object of extra args, as `name`: `value` pairs. Where the name is the command line arg to external-dns.           | `{}`                                               |
| `extraEnv`                         | Optional object of extra environment variables, as `name`: `value` pairs.                                                  | `{}`                                               |
| `image.name`                       | Container image name (Including repository name if not `hub.docker.com`).                                                  | `registry.opensource.zalan.do/teapot/external-dns` |
| `image.pullPolicy`                 | Container pull policy.                                                                                                     | `IfNotPresent`                                     |
| `image.tag`                        | Container image tag.                                                                                                       | `v0.4.5`                                           |
| `logLevel`                         | Verbosity of the logs (options: panic, debug, info, warn, error, fatal)                                                    | `info`                                             |
| `nodeSelector`                     | Node labels for pod assignment                                                                                             | `{}`                                               |
| `podAnnotations`                   | Additional annotations to apply to the pod.                                                                                | `{}`                                               |
| `policy`                           | Modify how DNS records are sychronized between sources and providers (options: sync, upsert-only ).                        | `upsert-only`                                      |
| `provider`                         | The DNS provider where the DNS records will be created (options: aws, google, azure, cloudflare, digitalocean, inmemory ). | `aws`                                              |
| `publishInternalServices`          | Allow external-dns to publish DNS records for ClusterIP services (optional).                                               | `false`                                            |
| `rbac.create`                      | If true, create & use RBAC resources                                                                                       | `false`                                            |
| `rbac.serviceAccountName`          | Existing ServiceAccount to use (ignored if rbac.create=true)                                                               | `default`                                          |
| `resources`                        | CPU/Memory resource requests/limits.                                                                                       | `{}`                                               |
| `service.annotations`              | Annotations to add to service                                                                                              | `{}`                                               |
| `service.clusterIP`                | IP address to assign to service                                                                                            | `""`                                               |
| `service.externalIPs`              | Service external IP addresses                                                                                              | `[]`                                               |
| `service.loadBalancerIP`           | IP address to assign to load balancer (if supported)                                                                       | `""`                                               |
| `service.loadBalancerSourceRanges` | List of IP CIDRs allowed access to load balancer (if supported)                                                            | `[]`                                               |
| `service.servicePort`              | Service port to expose                                                                                                     | `7979`                                             |
| `service.type`                     | Type of service to create                                                                                                  | `ClusterIP`                                        |
| `sources`                          | List of resource types to monitor, possible values are fake, service or ingress.                                           | `[service, ingress]`                               |
| `tolerations`                      | List of node taints to tolerate (requires Kubernetes >= 1.6)                                                               | `[]`                                               |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install --name my-release -f values.yaml stable/external-dns
```

> **Tip**: You can use the default [values.yaml](values.yaml)

## IAM Permissions

```json
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "route53:ChangeResourceRecordSets"
     ],
     "Resource": [
       "arn:aws:route53:::hostedzone/*"
     ]
   },
   {
     "Effect": "Allow",
     "Action": [
       "route53:ListHostedZones",
       "route53:ListResourceRecordSets"
     ],
     "Resource": [
       "*"
     ]
   }
 ]
}
```

[external-dns]: https://github.com/kubernetes-incubator/external-dns
[Zalando]: https://zalando.github.io/
[getting-started]: https://github.com/kubernetes-incubator/external-dns/blob/master/README.md#getting-started