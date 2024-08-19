## Middleware Kubernetes Agent

### Installation Process

Create a `middleware-values.yaml` using the content given below.
```
mw:
  target: XXXXXXXXX
  apiKey: XXXXXXXXX

clusterMetadata:
  name: my-cluster
```

Replace `XXXXXXXXX` with actual Middleware Target & API Key which you can get from your Middleware account => https://app.middleware.io

```
helm repo add middleware-labs https://helm.middleware.io
```
```
helm install mw-agent middleware-labs/mw-kube-agent-v2 -f middleware-values.yaml
```

#### Use Existing Secret for API Key ( Optional )

If you already have a secret named `my-custom-secret` that contains `middleware-api-key`, you can use it instead of putting your API Key in a local file.

```
mw:
  target: XXXXXXXXX
  apiKeyFromExistingSecret:
    enabled: true
    name: my-custom-secret
    key: middleware-api-key

clusterMetadata:
  name: my-cluster
```