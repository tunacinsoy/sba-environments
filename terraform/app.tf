# This hcl file is responsible for the configuration deployment that will be used by ArgoCD

# ApplicationSet resource for the applications that argoCD will manage
data "kubectl_file_documents" "apps" {
  content = file("../manifests/argocd/apps.yaml")
}

resource "kubectl_manifest" "apps" {
  # Needs to depend on argocd deployment, since we'll configure it after deployment finishes
  depends_on = [kubectl_manifest.argocd]
  # for_each iterates over each manifest in the namespace file
  for_each = data.kubectl_file_documents.apps.manifests
  # Applies the content of each manifest to the Kubernetes cluster
  yaml_body = each.value
  # Forces the namespace to be set to argocd, ensuring that all resources are created in the correct namespace
  override_namespace = "argocd"
}

# istio.yaml file contains charts for 'istio-base', 'istiod' and 'istio-ingress'
data "kubectl_file_documents" "istio" {
    content = file("../manifests/argocd/istio.yaml")
}

resource "kubectl_manifest" "istio" {
  depends_on = [
    kubectl_manifest.argocd,
  ]
  for_each  = data.kubectl_file_documents.istio.manifests
  yaml_body = each.value
  override_namespace = "argocd"
}

# # Cert-manager chart for the digital certificate creation
# data "kubectl_file_documents" "cert-manager" {
#     content = file("../manifests/argocd/cert-manager.yaml")
# }

# resource "kubectl_manifest" "cert-manager" {
#   depends_on = [
#     kubectl_manifest.argocd,
#   ]
#   for_each  = data.kubectl_file_documents.cert-manager.manifests
#   yaml_body = each.value
#   override_namespace = "argocd"
# }

# I am done with externalSecrets, a lot of problems
# Managing Secrets using ExternalSecrets Operator
# # External-Secrets operator for the retrieval of secrets
# data "kubectl_file_documents" "external-secrets" {
#   content = file("../manifests/argocd/external-secrets.yaml")
# }

# resource "kubectl_manifest" "external-secrets" {
#   #It needs to depend on the creation of ArgoCD, since we'll deploy external-secrets right after ArgoCD is created.
#   depends_on = [
#     kubectl_manifest.argocd,
#   ]
#   # for_each iterates over each manifest in the namespace file
#   for_each = data.kubectl_file_documents.external-secrets.manifests
#   # Applies the content of each manifest to the Kubernetes cluster
#   yaml_body = each.value
#   # Forces the namespace to be set to argocd, ensuring that all resources are created in the correct namespace
#   override_namespace = "argocd"
# }

# # File that holds the secret resource that have service account credentials.
# # It is used by ClusterSecretStore object to access GCP Secret Manager to retrieve application secrets.
# data "kubectl_file_documents" "gcpsm-secret" {
#   content = file("../manifests/argocd/gcpsm-secret.yaml")
# }

# resource "kubectl_manifest" "gcpsm-secret" {
#   for_each  = data.kubectl_file_documents.gcpsm-secret.manifests
#   yaml_body = each.value
# }

# # ClusterSecretStore resource uses k8s-secret resource to retrieve application secrets from google cloud secret manager
# data "kubectl_file_documents" "cluster-secret-store" {
#   content = file("../manifests/argocd/cluster-secret-store.yaml")
# }

# resource "kubectl_manifest" "cluster-secret-store" {
#   depends_on = [
#     kubectl_manifest.gcpsm-secret,
#   ]
#   for_each  = data.kubectl_file_documents.cluster-secret-store.manifests
#   yaml_body = each.value
# }

