# Komodo Helm Chart

Helm chart to deploy [Komodo](https://komo.do/) Core with MongoDB on Kubernetes.

## Install

```bash
helm repo add komodo https://antiantiops.github.io/komodo-helm-chart
helm repo update
helm upgrade --install komodo komodo/komodo \
  --namespace komodo --create-namespace \
  --set komodo.host=https://komodo.example.com \
  --set komodo.auth.initAdminPassword='change-me' \
  --set komodo.auth.jwtSecret='replace-with-random-secret' \
  --set komodo.auth.passkey='replace-with-random-secret' \
  --set komodo.auth.webhookSecret='replace-with-random-secret' \
  --set mongo.auth.rootPassword='change-me'
```

For production, place all secrets in an existing Secret and set `existingSecret.name`.

```yaml
# values-prod.yaml
existingSecret:
  name: komodo-secrets
komodo:
  host: https://komodo.example.com
  persistence:
    storageClass: longhorn
mongo:
  persistence:
    storageClass: longhorn
```

The existing Secret must contain `mongo-root-password`, `komodo-init-admin-password`, `komodo-jwt-secret`, `komodo-passkey`, and `komodo-webhook-secret`.

## Notes

- `komodo.host` must be the externally reachable URL of Komodo Core.
- `komodo.persistence.repoCache` retains cloned repositories and build cache; `config` retains Komodo config.
- MongoDB is a single-replica StatefulSet. Back up its PVC before upgrades or deletion.
