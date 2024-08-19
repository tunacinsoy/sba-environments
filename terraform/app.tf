# This hcl file is responsible for the configuration deployment that will be used by ArgoCD

# ApplicationSet resource for the applications that argoCD will manage
data "kubectl_file_documents" "apps" {
  content = file("../manifests/argocd/apps.yaml")
}

resource "kubectl_manifest" "apps" {
  # Needs to depend on argocd deployment, since we'll configure it after deployment finishes
  depends_on = [kubectl_manifest.argocd]
  # for_each iterates over each manifest in the namespace file
  for_each           = data.kubectl_file_documents.apps.manifests
  # Applies the content of each manifest to the Kubernetes cluster
  yaml_body          = each.value
  # Forces the namespace to be set to argocd, ensuring that all resources are created in the correct namespace
  override_namespace = "argocd"
}

# MANAGING SECRETS USING External Secrets
# # External-Secrets operator for the retrieval of secrets
# data "kubectl_file_documents" "external-secrets" {
#   content = file("../manifests/argocd/external-secrets.yaml")
# }

# resource "kubectl_manifest" "external-secrets" {
#   # It needs to depend on argocd creation, since we'll deploy external-secrets right after argocd gets created
#   depends_on = [kubectl_manifest.argocd]
#   # for_each iterates over each manifest in the namespace file
#   for_each = data.kubectl_file_documents.external-secrets.manifests
#   # Applies the content of each manifest to the Kubernetes cluster
#   yaml_body = each.value
#   # Forces the namespace to be set to argocd, ensuring that all resources are created in the correct namespace
#   override_namespace = "argocd"
# }

# # File that holds the secret resource that have service account credentials
# # and clusterSecretStore resource that uses credentials to retrieve external secrets
# data "kubectl_file_documents" "gcpsm-secret" {
#     content = file("../manifests/argocd/gcpsm-secret.yaml")
# }

# resource "kubectl_manifest" "gcpsm-secrets" {
#   depends_on = [
#     kubectl_manifest.external-secrets,
#   ]
#   for_each  = data.kubectl_file_documents.gcpsm-secret.manifests
#   yaml_body = each.value
# }

