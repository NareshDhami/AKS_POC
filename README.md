# AKS_POC
## Quick overview

- Provisions Azure cloud infrastructure using Bicep templates and Azure DevOps pipelines.
- Creates an Azure Kubernetes Service (AKS) cluster to run containerized applications.
- Configures virtual networking, Application Gateway ingress, managed identities, and access permissions.
- Deploys the comments, posts, users, and posthub microservices alongside a frontend UI.
- Packages the applications as Docker images and publishes them to Azure Container Registry (ACR).
- Uses CI/CD pipelines to build images and deploy Kubernetes manifests to AKS, which pulls images from ACR.
- Includes Kubernetes resources for MongoDB databases and NATS messaging between services.
- Provides a manually triggered pipeline to delete selected resource groups and their resources.
- This code was used to create infrastructure and was fully tested in Azure cloud.

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
