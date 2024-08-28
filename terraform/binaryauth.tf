# For each image we used in deployment.yaml file, we attest them using the keyring that we have created.
# To attest them, we need to retrieve the private key; and for the verification, we need public key.
resource "google_kms_key_ring" "qa-attestor-keyring" {
  count    = var.branch == "dev" ? 1 : 0
  name     = "qa-attestor-keyring"
  location = var.region
  lifecycle {
    prevent_destroy = false
  }
}

# qa-attestor uses the private key to sign images, so that they will be authorized to use in prod environment.
# Remember, we do not check if image is attested or not in dev env, we are actually doing attestation in dev environment in our demo.
module "qa-attestor" {
  count         = var.branch == "dev" ? 1 : 0
  source        = "terraform-google-modules/kubernetes-engine/google//modules/binary-authorization"
  attestor-name = "quality-assurance"
  project_id    = var.project_id
  # Using [0] explicitly accesses the first (and possibly only) element of that list.
  # This is needed because Terraform treats even a single resource created with a count as a list of resources.
  keyring-id = google_kms_key_ring.qa-attestor-keyring[0].id
}

# These policies are applied only for dev environment.
#Following whitelists are ignored, since we can trust images which have these patterns associated with them.
resource "google_binary_authorization_policy" "policy" {
  count = var.branch == "dev" ? 1 : 0
  admission_whitelist_patterns {
    name_pattern = "gcr.io/google_containers/*"
  }
  admission_whitelist_patterns {
    name_pattern = "gcr.io/google-containers/*"
  }
  admission_whitelist_patterns {
    name_pattern = "k8s.gcr.io/**"
  }
  admission_whitelist_patterns {
    name_pattern = "gke.gcr.io/**"
  }
  admission_whitelist_patterns {
    name_pattern = "gcr.io/stackdriver-agents/*"
  }
  admission_whitelist_patterns {
    name_pattern = "quay.io/argoproj/*"
  }
  admission_whitelist_patterns {
    name_pattern = "ghcr.io/dexidp/*"
  }
  admission_whitelist_patterns {
    name_pattern = "docker.io/redis[@:]*"
  }
  admission_whitelist_patterns {
    name_pattern = "ghcr.io/external-secrets/*"
  }
  # This setting enables global policy evaluation, meaning the policy applies to all clusters unless explicitly overridden
  global_policy_evaluation_mode = "ENABLE"
  # This part specifies the default behavior for images that do not match any whitelist patterns
  default_admission_rule {
    # Images must have an attestation, which is a signed statement that verifies the image meets certain criteria
    evaluation_mode = "REQUIRE_ATTESTATION"
    # This mode enforces the policy by blocking untrusted images and logging the action.
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [
      # Specifies which attestors (trusted authorities) are required for an image
      module.qa-attestor[0].attestor
    ]
  }
}