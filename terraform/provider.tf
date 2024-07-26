provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

terraform {
  backend "gcs" {
    #bucket  = "tf-state-mdo-terraform-${var.project_id}"
    prefix = var.prefix
  }
}
