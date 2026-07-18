# Argo CD deployment

`komodo-application.yaml` installs chart `komodo` version `0.1.0` into namespace
`komodo`, with an HTTP NGINX Ingress at `komodo.nimtechnology.com`.

The Application deliberately references an existing Kubernetes Secret named
`komodo-auth`; credentials are not committed to this public repository.
Required keys are: `mongo-root-password`, `komodo-init-admin-password`,
`komodo-jwt-secret`, `komodo-passkey`, and `komodo-webhook-secret`.
