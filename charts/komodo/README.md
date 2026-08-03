# Komodo Helm Chart

Helm chart for deploying [Komodo](https://github.com/mbecker20/komodo) - a server management and automation platform.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+

## Installing the Chart

To install the chart with the release name `komodo`:

```bash
helm repo add antiantiops https://antiantiops.github.io/komodo-helm-chart
helm install komodo antiantiops/komodo --namespace komodo --create-namespace
```

## Uninstalling the Chart

To uninstall/delete the `komodo` deployment:

```bash
helm delete komodo --namespace komodo
```

## External MongoDB

By default, this Helm chart deploys MongoDB as a dependency subchart. If you already have a MongoDB instance managed outside of Kubernetes, you can configure Komodo to use an external MongoDB database by enabling `externalMongodb`.

When `externalMongodb.enabled` is set to `true`:

- The MongoDB subchart is not deployed.
- The chart creates a Kubernetes Secret named `komodo-external-mongodb-secret` containing the MongoDB credentials.
- The Komodo deployment uses this Secret to configure:
  - `KOMODO_MONGO_ADDRESS`
  - `KOMODO_MONGO_USERNAME`
  - `KOMODO_MONGO_PASSWORD`

### Example values.yaml

```yaml
externalMongodb:
  enabled: true
  host: "mongodb.example.com"
  port: 27017
  user: "komodo"
  password: "change-me"
  database: "komodo"
  authSource: "admin"
```

Install or upgrade the chart with the custom values:

```bash
helm upgrade --install komodo ./charts/komodo \
  --namespace komodo \
  --create-namespace \
  -f values.yaml
```

### External MongoDB connection requirements

The external MongoDB instance must be reachable from the Kubernetes cluster where Komodo is deployed.

Ensure that:

- The MongoDB service allows network connections from your Kubernetes nodes/pods.
- The configured user has permission to access the configured database.
- The authentication database (`authSource`) matches the MongoDB user configuration.
- MongoDB version compatibility is maintained with the Komodo application requirements.

### Disabling the bundled MongoDB

When using an external MongoDB instance, the bundled MongoDB dependency should remain disabled. The chart handles this automatically when `externalMongodb.enabled=true`.

## Best practices for external MongoDB

| Area | Recommendation |
|---|---|
| Authentication | Use a dedicated MongoDB user for Komodo instead of sharing an administrative account. Grant only the required database permissions. |
| Password management | Avoid committing MongoDB passwords into Git. Use Helm secrets management solutions such as External Secrets Operator, SOPS, or sealed secrets where possible. |
| TLS/SSL | Enable MongoDB TLS for production deployments, especially when MongoDB is hosted outside the Kubernetes cluster or across networks. |
| Network security | Restrict MongoDB access using firewall rules, security groups, Kubernetes NetworkPolicies, or private networking. |
| Backups | Configure regular MongoDB backups and verify restore procedures before running production workloads. |
| High availability | Use MongoDB replica sets or managed MongoDB services for production environments requiring availability guarantees. |
| Monitoring | Monitor MongoDB connection health, storage usage, replication status, slow queries, and resource consumption. |
| Credentials rotation | Rotate MongoDB credentials periodically and update Kubernetes secrets accordingly. |
| Database isolation | Use a dedicated database (for example `komodo`) instead of sharing the same database with unrelated applications. |

## Frequently Asked Questions

### Does enabling external MongoDB deploy the MongoDB subchart?

No. When `externalMongodb.enabled=true`, the bundled MongoDB dependency is not deployed. Komodo connects directly to the external MongoDB instance.

### What value should I use for `authSource`?

`authSource` is the MongoDB authentication database where the user was created.

For example, if the user was created in the `admin` database:

```yaml
externalMongodb:
  authSource: "admin"
```

If the user was created inside the application database:

```yaml
externalMongodb:
  database: "komodo"
  authSource: "komodo"
```

### Can I use a managed MongoDB service?

Yes. External MongoDB can be used with managed services such as MongoDB Atlas or cloud provider MongoDB offerings, as long as the Kubernetes cluster can reach the MongoDB endpoint and authentication is configured correctly.

### How do I verify the MongoDB connection?

Check the Komodo pod logs after deployment:

```bash
kubectl logs -n komodo deployment/komodo
```

If the connection fails, verify:

- MongoDB hostname and port
- Network connectivity from the cluster
- Username/password
- Authentication database (`authSource`)
- TLS requirements

### Should I enable TLS for external MongoDB?

For production environments, TLS is strongly recommended. Configure MongoDB and the network path according to your MongoDB provider's TLS requirements before connecting Komodo.

## Configuration

The following table lists the configurable parameters of the Komodo chart and their default values.

<!-- helm-docs will auto-generate parameters table here -->

## License

This Helm chart is licensed under the Apache License 2.0.
