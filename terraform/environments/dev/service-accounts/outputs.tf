# =============================================================================
# Outputs for Service Accounts Deployment (Pipeline 1)
# These outputs are captured by Harness and stored in Secret Manager
# =============================================================================

# -----------------------------------------------------------------------------
# Confluent Outputs
# -----------------------------------------------------------------------------

output "confluent_service_account_id" {
  description = "ID of the created Confluent service account"
  value       = module.confluent_service_account.service_account_id
}

output "confluent_service_account_name" {
  description = "Name of the created Confluent service account"
  value       = module.confluent_service_account.service_account_name
}

output "confluent_kafka_api_key" {
  description = "Kafka API key for the connector"
  value       = module.confluent_service_account.kafka_api_key
  sensitive   = true
}

output "confluent_kafka_api_secret" {
  description = "Kafka API secret for the connector"
  value       = module.confluent_service_account.kafka_api_secret
  sensitive   = true
}

# -----------------------------------------------------------------------------
# GCP Outputs
# -----------------------------------------------------------------------------

output "gcp_service_account_email" {
  description = "Email of the created GCP service account"
  value       = module.gcp_service_account.service_account_email
}

output "gcp_service_account_key_base64" {
  description = "Base64-encoded GCP service account key (for Confluent connector)"
  value       = module.gcp_service_account.gcp_sa_key_base64
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Summary Output (for logging)
# -----------------------------------------------------------------------------

output "deployment_summary" {
  description = "Summary of created resources (non-sensitive)"
  value = {
    confluent_service_account = module.confluent_service_account.service_account_id
    gcp_service_account       = module.gcp_service_account.service_account_email
    target_topic              = var.kafka_topic
    pubsub_subscription       = var.pubsub_subscription_id
  }
}
