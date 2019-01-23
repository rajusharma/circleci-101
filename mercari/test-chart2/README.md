# pull-request-replication-controller
https://github.com/kouzoh/pull-request-replication-controller

## Installing the Chart
To install the chart with release name:

```bash
# Add mercari repo
$ helm repo add mercari http://mercari:${PASSWORD}@chartmuseum.citadelapps.com
```

```bash
$ helm install --name pull-request-replication-controller \
  --set githubToken=YOUR_GITHUB_TOKEN \
  mercari/pull-request-replication-controller
```

## Uninstalling the Chart
To uninstall/delete:

```bash
$ helm delete pull-request-replication-controller --purge
```
