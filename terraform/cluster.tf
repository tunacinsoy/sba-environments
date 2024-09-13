# This file is responsible for the creation of gke cluster, and a service account.

resource "google_service_account" "main" {
  # Since there will be two clusters for 'prod' and 'dev' envs, we need to be able to
  # distinguish their service accounts.
  account_id   = "gke-${var.cluster_name}-${var.branch}-sa"
  display_name = "GKE Cluster ${var.cluster_name}-${var.branch} Service Account"
}

#After the creation of service account, the email attribute will be exposed automatically.
#With locals definition, it will be more readable for users to see which attributes are created.
locals {
  service_account_email = google_service_account.main.email
}
# trigger
resource "google_container_cluster" "main" {
  name               = "${var.cluster_name}-${var.branch}"
  location           = var.location
  initial_node_count = 2

  # Only for prod env it will be deployed, since prod won't accept not-attested images
  dynamic "binary_authorization" {
    for_each = var.branch == "prod" ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  node_config {
    # 4 vcpu, 16 gb ram
    machine_type    = "e2-standard-4"
    service_account = local.service_account_email # Retrieving the email of the service account from locals
    disk_size_gb    = 50                          # Setting persistent disk ssd size, quota is 250 GB
    oauth_scopes = [
      # This scope is a Google Cloud OAuth scope that grants the client full access to all Google Cloud services.
      # It’s a broad scope that allows the application or service account to perform any action across the entire Google Cloud Platform,
      # including managing resources, accessing APIs, and interacting with various services.
      "https://www.googleapis.com/auth/cloud-platform"

    ]
  }

  # Defines how long Terraform should wait for the create and update operations to complete.
  timeouts {
    create = "30m" # Allows up to 30 minutes for the cluster creation process
    update = "40m" # Allows up to 40 minutes for the cluster update process
  }
}