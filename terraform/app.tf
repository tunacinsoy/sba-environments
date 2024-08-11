# This hcl file is responsible for the configuration deployment that will be used by ArgoCD

data "kubectl_file_documents" "apps" {
  content = file("../manifests/argocd/apps.yaml")
}

resource "kubectl_manifest" "apps" {
  # Needs to depend on argocd deployment, since we'll configure it after deployment finishes
  depends_on = [kubectl_manifest.argocd]
  for_each           = data.kubectl_file_documents.apps.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}
