# This variable will be initialized from cli using --vars flag
# during the workflow process. It will be retrived from repository secrets.
variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

# For provider "google"
variable "region" {
  description = "region where the resources will be deployed"
  type        = string
  default     = "europe-central2"
}

# For provider "google"
variable "zone" {
  description = "zone where the resources will be deployed"
  type        = string
  default     = "europe-central2-b"
}

# For resource google_service_account.main
variable "cluster_name" {
  type        = string
  description = "GKE Cluster Name"
  default     = "sba-cluster"
}

# This variable will be initialized from cli using --vars flag during the workflow process.
# It will be retrieved from current branch name.
# For resource google_service_account.main
variable "branch" {
  description = "Git Branch Name"
  type        = string
  default     = "dev"
}

# For resource google_container_cluster_main
variable "location" {
  type        = string
  description = "GKE Cluster Location"
  default     = "europe-central2-b"
}
