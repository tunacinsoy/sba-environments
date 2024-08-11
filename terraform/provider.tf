# This hcl file is responsible for defining necessary providers for the deployment

# This block ensures that Terraform knows which GCP project and region/zone to use when creating or managing resources
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "kubectl" {
  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
  # Ensures Terraform uses the connection details provided directly in the
  # Terraform configuration (e.g., host, cluster_ca_certificate, token), rather than relying on the local Kubernetes config file (~/.kube/config).
  load_config_file       = false
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
  backend "gcs" {
    # Terraform state files will be located in the following path:
    # tf-state-sba-terraform-${{ secrets.PROJECT_ID }}/sba-terraform/${GITHUB_REF##*/}.tfstate
    prefix = "sba-terraform"
  }
}
