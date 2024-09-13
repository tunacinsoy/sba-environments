# # This hcl file is responsible for the deployment of argocd to the existing gke cluster.

# # This ensures that the delay happens only after the GKE cluster has been created
# resource "time_sleep" "wait_30_seconds" {
#   depends_on      = [google_container_cluster.main]
#   create_duration = "30s"
# }

# # Authenticating with the GKE Cluster
# # Terraform needs to authenticate to gke cluster to be able to apply manifest files
# module "gke_auth" {
#   depends_on = [time_sleep.wait_30_seconds]
#   # This module is sourced from the Terraform Google modules for Kubernetes Engine and is specifically for setting up authentication
#   source               = "terraform-google-modules/kubernetes-engine/google//modules/auth"
#   project_id           = var.project_id
#   cluster_name         = google_container_cluster.main.name
#   location             = var.location
#   use_private_endpoint = false
# }
#
# # Manifest file that creates argocd namespace
# data "kubectl_file_documents" "namespace" {
#   content = file("../manifests/argocd/namespace.yaml")
# }

# # Creates argocd namespace within our k8s cluster.
# resource "kubectl_manifest" "namespace" {
#   # for_each iterates over each manifest in the namespace file
#   for_each = data.kubectl_file_documents.namespace.manifests
#   # Applies the content of each manifest to the Kubernetes cluster
#   yaml_body = each.value
#   # Forces the namespace to be set to argocd, ensuring that all resources are created in the correct namespace
#   override_namespace = "argocd"
# }

# # Installation script for argocd, retrieved from its repository.
# data "kubectl_file_documents" "argocd" {
#   content = file("../manifests/argocd/install.yaml")
# }

# resource "kubectl_manifest" "argocd" {
#   # It needs to depend on namespace creation, since we'll deploy argocd into argocd namespace
#   depends_on = [kubectl_manifest.namespace]
#   # for_each iterates over each manifest in the namespace file
#   for_each = data.kubectl_file_documents.argocd.manifests
#   # Applies the content of each manifest to the Kubernetes cluster
#   yaml_body = each.value
#   # Forces the namespace to be set to argocd, ensuring that all resources are created in the correct namespace
#   override_namespace = "argocd"
# }
