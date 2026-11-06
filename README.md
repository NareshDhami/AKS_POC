# AKS_POC
Deploying microservices to Auzure kubernetes services using azure container services

## Repository layout

- [microservices](microservices): comments, posts, users, and posthub services.
- [infrastructure](infrastructure): CD and CI pipelines, k8s resources, and manifests.
- [ui](ui): the frontend application.
- [resources](resources): deployment guides and exercise resources.

Azure DevOps pipeline definitions now live under `infrastructure/CI` and
`infrastructure/CD`. Update existing pipeline YAML paths in Azure DevOps to match.
The shared CI variables use `microservices/$(microservice)` for `serviceFolder`
and `infrastructure/k8s` for `k8sFolder`; the UI pipeline sets `serviceFolder` to
`ui`. Update any externally configured path overrides to match this layout.
