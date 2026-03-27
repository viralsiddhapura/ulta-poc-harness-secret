# =============================================================================
# GCP Service Account Module
# Creates a service account with Pub/Sub read permissions for Confluent connector
# =============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Service Account - For Pub/Sub access
# -----------------------------------------------------------------------------

resource "google_service_account" "pubsub_reader" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
  description  = "Service account for Confluent Cloud connector to read from Pub/Sub - managed by Harness Terraform"
  project      = var.gcp_project_id
}

# -----------------------------------------------------------------------------
# IAM Bindings - Grant Pub/Sub Subscriber role
# -----------------------------------------------------------------------------

# Subscription-level binding (recommended - least privilege)
resource "google_pubsub_subscription_iam_member" "subscriber" {
  count = var.pubsub_subscription_id != "" ? 1 : 0

  project      = var.gcp_project_id
  subscription = var.pubsub_subscription_id
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.pubsub_reader.email}"
}

# Optional: Project-level binding for viewing subscriptions
resource "google_project_iam_member" "pubsub_viewer" {
  count = var.grant_project_viewer ? 1 : 0

  project = var.gcp_project_id
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:${google_service_account.pubsub_reader.email}"
}

# -----------------------------------------------------------------------------
# Service Account Key - JSON credentials for Confluent connector
# -----------------------------------------------------------------------------

resource "google_service_account_key" "pubsub_reader_key" {
  service_account_id = google_service_account.pubsub_reader.name
  key_algorithm      = "KEY_ALG_RSA_2048"

  # Key will be rotated when this resource is recreated
  # Consider using Workload Identity for production
}

# -----------------------------------------------------------------------------
# Local - Base64 encode the key for Confluent connector
# -----------------------------------------------------------------------------

locals {
  # The private_key is already base64 encoded by GCP
  # Decode it to get the JSON, which can be stored in Harness
  gcp_sa_key_json = base64decode(google_service_account_key.pubsub_reader_key.private_key)

  # Re-encode for Confluent connector (which expects base64)
  gcp_sa_key_base64 = google_service_account_key.pubsub_reader_key.private_key
}
