# Komodo

[Komodo](https://komo.do/) is an open-source platform for deploying and managing
servers, Docker workloads, repositories, builds, and alerts. This chart deploys
**Komodo Core** together with a single-replica **MongoDB** database.

## Prerequisites

- Kubernetes 1.25+
- Helm 3.12+
- A default StorageClass, or a `storageClass` set for every enabled persistent volume
- An Ingress controller when `komodo.ingress.enabled=true`

## Install

```bash
helm repo add komodo https://antiantiops.github.io/komodo-helm-chart
helm repo update

helm upgrade --install komodo komodo/komodo \
  --namespace komodo --create-namespace \
  --set komodo.host=https://komodo.example.com \
  --set komodo.auth.initAdminPassword='change-me' \
  --set komodo.auth.jwtSecret='replace-with-a-random-value' \
  --set komodo.auth.passkey='replace-with-a-random-value' \
  --set komodo.auth.webhookSecret='replace-with-a-random-value' \
  --set mongo.auth.rootPassword='change-me'
```

## Production secrets

Do not put credentials into Git. Create a Secret first and reference it with
`existingSecret.name`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: komodo-auth
  namespace: komodo
type: Opaque
stringData:
  mongo-root-password: replace-me
  komodo-init-admin-password: replace-me
  komodo-jwt-secret: replace-me
  komodo-passkey: replace-me
  komodo-webhook-secret: replace-me
```

```yaml
# values-production.yaml
existingSecret:
  name: komodo-auth

komodo:
  host: https://komodo.example.com
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: komodo.example.com
        paths:
          - path: /
            pathType: Prefix
  persistence:
    config:
      storageClass: longhorn
    repoCache:
      storageClass: longhorn

mongo:
  persistence:
    storageClass: longhorn
```

Install with `helm upgrade --install komodo komodo/komodo -n komodo -f values-production.yaml`.

## Persistence

| Component | Default | Purpose |
| --- | ---: | --- |
| `komodo.persistence.config` | 1Gi | Komodo configuration and generated keys |
| `komodo.persistence.repoCache` | 10Gi | Repository and build cache |
| `mongo.persistence` | 10Gi | Komodo database |

MongoDB is deployed as a single-replica StatefulSet. Back up its PVC before
upgrades or deletion.

## Important values

| Value | Default | Description |
| --- | --- | --- |
| `komodo.host` | `http://komodo.local` | Public URL used by Komodo Core |
| `komodo.localAuth` | `true` | Enable local username/password login |
| `komodo.ingress.enabled` | `false` | Create an Ingress resource |
| `komodo.ingress.className` | `""` | IngressClass, for example `nginx` |
| `existingSecret.name` | `""` | Existing secret holding all required credentials |
| `mongo.persistence.storageClass` | `""` | StorageClass for MongoDB PVC |

When `existingSecret.name` is empty, values under `komodo.auth` and
`mongo.auth` are rendered into a Secret by the chart. For production, use an
existing Secret instead.
