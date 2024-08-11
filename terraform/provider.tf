provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

terraform {
  backend "gcs" {
    # Terraform state files will be located in the following path:
    # tf-state-sba-terraform-${{ secrets.PROJECT_ID }}/sba-terraform/terraform.tfstateenv:${GITHUB_REF##*/}
    prefix = "sba-terraform"
  }
}
