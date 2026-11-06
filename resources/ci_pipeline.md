# Replace ** in Docker File field
$(serviceFolder)/Dockerfile

Use `microservices/$(microservice)` for `serviceFolder`, or `ui` for the UI pipeline.
Set `k8sFolder` to `infrastructure/k8s`.

# Image name field
$(Build.Repository.Name)-$(Build.SourceBranchName)-$(microservice):$(Build.BuildId)

# Replace content in target files field
$(k8sFolder)/prod-manifests/$(microservice).yaml
$(k8sFolder)/prod-manifests/$(ingressTokenizedYamlFile)
$(k8sFolder)/$(natsTokenizedYamlFile)
$(k8sFolder)/$(microservice)-mongo.yaml
ui/.env

# Default value for the variable
-$(Build.SourceBranchName)

# Target file for __ImageTag__ replacement
$(k8sFolder)/prod-manifests/$(microservice).yaml

# Default value for the variable __ImageTag__
acrName.azurecr.io/$(Build.Repository.Name)-$(Build.SourceBranchName)-$(microservice):$(Build.BuildId)

# Copy target files task
$(k8sFolder)/prod-manifests/$(microservice).yaml
$(k8sFolder)/prod-manifests/$(ingressTokenizedYamlFile)
$(k8sFolder)/$(natsTokenizedYamlFile)
$(k8sFolder)/$(microservice)-mongo.yaml

# Target folder
$(build.artifactstagingdirectory)