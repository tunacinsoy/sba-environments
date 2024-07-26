# This variable will be initialized from cli using --vars flag
# during the workflow process. It will be retrived from repository secrets.
variable "project_id" {}

# For provider "google"
variable "region" {
  description = "region where the resources will be deployed"
  type        = string
  default     = "me-west"
}

# For provider "google"
variable "zone" {
  description = "zone where the resources will be deployed"
  type        = string
  default     = "me-west1-b"
}

# For terraform backend "gcs"
variable "prefix" {
  description = "prefix for remote backend for terraform state files"
  type        = string
  default     = "sba-terraform"
}

# For resource google_service_account.main
variable "cluster_name" {
  type        = string
  description = "GKE Cluster Name"
  default     = "sba-cluster"
}

# This variable will be initialized from cli using --vars flag
# during the workflow process. It will be retrieved from current branch name.
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
  default     = "me-west1-b"
}
