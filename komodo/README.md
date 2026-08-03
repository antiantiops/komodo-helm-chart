# Komodo

[Komodo](https://komo.do/) is an open-source platform for deploying and managing
servers, Docker workloads, repositories, builds, and alerts. This chart deploys
**Komodo Core** together with a single-replica embedded **MongoDB** database by
default. It can also use an external MongoDB-compatible endpoint.

## Prerequisites

- Kubernetes 1.25+
- Helm 3.12+
- A default StorageClass, or a `storageClass` set for every enabled persistent volume
- An Ingress controller when `komodo.ingress.enabled=true`

## Generate random secrets

Before installing the chart, generate secure random values for the Komodo authentication secrets.

You can generate a secret using `openssl`:

```bash
openssl rand -base64 32
```

Generate four values and use them for:

- `komodo.auth.initAdminPassword`
- `komodo.auth.jwtSecret`
- `komodo.auth.passkey`
- `komodo.auth.webhookSecret`

Example:

```bash
export ADMIN_PASSWORD=$(openssl rand -base64 32)
export JWT_SECRET=$(openssl rand -base64 32)
export PASSKEY=$(openssl rand -base64 32)
export WEBHOOK_SECRET=$(openssl rand -base64 32)
```

Then use these values in your Helm install command:

```bash
helm upgrade --install komodo komodo/komodo \
  --namespace komodo --create-namespace \
  --set komodo.host=https://komodo.example.com \
  --set komodo.auth.initAdminPassword="$ADMIN_PASSWORD" \
  --set komodo.auth.jwtSecret="$JWT_SECRET" \
  --set komodo.auth.passkey="$PASSKEY" \
  --set komodo.auth.webhookSecret="$WEBHOOK_SECRET" \
  --set mongo.auth.password='change-me'
```

Keep these values private and do not commit them to version control.

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
  --set mongo.auth.password='change-me'
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
  # Historical key name retained for upgrade compatibility; this is the
  # password for mongo.auth.username, not necessarily a root password.
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

## MongoDB modes

`mongo.mode` selects where Komodo gets its database:

- `embedded` (default): this chart creates the MongoDB StatefulSet and Service.
- `external`: this chart does not create MongoDB resources; Komodo connects to
  `mongo.host:mongo.port`.

The same app credential model is used in both modes: Komodo uses
`mongo.auth.username` and the existing `mongo-root-password` key in the chart Secret
or in `existingSecret.name`.

### Using an external MongoDB instance

Use an external MongoDB deployment when you already have a managed MongoDB service (such as MongoDB Atlas), an organization-wide MongoDB cluster, or a production database environment managed separately from Kubernetes.

When using `mongo.mode=external`, the chart will not create a MongoDB StatefulSet. Instead, the application connects to the MongoDB instance configured through `mongo.host`, `mongo.port`, and authentication settings.

**Connection format:** The chart configures Komodo with individual connection parameters (`host:port`, username, password) rather than a MongoDB connection URI. The Komodo application determines the database name internally; this chart does not expose a `mongo.database` configuration value.

Example external database configuration:

```yaml
existingSecret:
  name: komodo-auth

mongo:
  mode: external
  host: mongodb-prod.example.com
  port: 27017
  auth:
    username: komodo
```

The external database/user must already exist and be reachable from the Komodo
namespace.

Install or upgrade with the external configuration:

```bash
helm upgrade --install komodo komodo/komodo \
  --namespace komodo \
  --create-namespace \
  -f values-external-mongo.yaml
```

### External MongoDB requirements

Before deploying Komodo with an external MongoDB instance, verify the following:

| Requirement | Description |
|---|---|
| Network connectivity | Kubernetes workloads must be able to reach the MongoDB host and port (`27017` by default). |
| Firewall rules | Allow inbound MongoDB traffic only from trusted Kubernetes node/network ranges. |
| Authentication | Create a dedicated MongoDB user for Komodo with required database permissions. |
| Database access | Ensure the configured user has access to the Komodo application database. |
| MongoDB version | Use a MongoDB version compatible with the Komodo application requirements. |
| TLS configuration | Enable TLS for production MongoDB deployments whenever supported by the environment. |
| Credentials | Store MongoDB credentials securely using Kubernetes Secrets or an external secrets manager. |
| DNS resolution | The Kubernetes cluster must be able to resolve the configured MongoDB hostname. |
| Connection limits | Ensure MongoDB connection limits are sized for the expected Komodo workload. |

### External MongoDB best practices

| Area | Recommendation |
|---|---|
| Security | Use TLS encryption and restrict MongoDB network access to only required clients. |
| Authentication | Use a dedicated MongoDB account instead of shared administrative users. |
| Credentials management | Avoid committing passwords into Git; use Kubernetes Secrets or secret management solutions. |
| Backup | Configure regular MongoDB backups and verify restore procedures before production use. |
| High availability | Use MongoDB replica sets or managed MongoDB services for production workloads. |
| Monitoring | Enable MongoDB metrics monitoring, alerts, and slow query analysis. |
| Performance | Monitor CPU, memory, storage latency, and connection usage. |
| Disaster recovery | Document recovery procedures and test failover scenarios periodically. |

### FAQ

#### Can I use MongoDB Atlas with `mongo.mode=external`?

Yes. Configure the Atlas cluster connection endpoint as `mongo.host` and ensure the Kubernetes cluster can access the Atlas network endpoint.

#### Will the Helm chart create MongoDB resources in external mode?

No. When `mongo.mode=external` is enabled, the chart only configures the application to connect to the existing MongoDB instance.

#### What happens if the MongoDB credentials are incorrect?

The Komodo application will fail to connect to MongoDB. Check application logs and verify the username, password, database permissions, and network connectivity.

#### Can I migrate from embedded MongoDB to an external MongoDB instance?

Yes. Migration requires exporting data from the embedded MongoDB instance and importing it into the external MongoDB deployment before switching `mongo.mode` to `external`.

#### Should I use external MongoDB in production?

For production environments, an externally managed MongoDB cluster is recommended because it provides better backup, availability, security, and operational control compared with running MongoDB inside the application Helm release.

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
