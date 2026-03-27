# =============================================================================
# Outputs for GCP Service Account Module
# These outputs will be stored in Harness Secret Manager by Pipeline 1
# =============================================================================

output "service_account_email" {
  description = "The email address of the created service account"
  value       = google_service_account.pubsub_reader.email
}

output "service_account_name" {
  description = "The fully qualified name of the service account"
  value       = google_service_account.pubsub_reader.name
}

output "service_account_id" {
  description = "The unique ID of the service account"
  value       = google_service_account.pubsub_reader.unique_id
}

output "gcp_sa_key_json" {
  description = "The service account key in JSON format (for storing in Harness)"
  value       = local.gcp_sa_key_json
  sensitive   = true
}

output "gcp_sa_key_base64" {
  description = "The service account key in base64 format (for Confluent connector)"
  value       = local.gcp_sa_key_base64
  sensitive   = true
}

# Combined output for easy reference
output "gcp_credentials" {
  description = "Combined GCP credentials object"
  value = {
    service_account_email = google_service_account.pubsub_reader.email
    service_account_name  = google_service_account.pubsub_reader.name
    project_id            = var.gcp_project_id
    key_json              = local.gcp_sa_key_json
    key_base64            = local.gcp_sa_key_base64
  }
  sensitive = true
}
