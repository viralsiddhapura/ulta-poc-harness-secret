# =============================================================================
# Outputs for Confluent Service Account Module
# These outputs will be stored in Harness Secret Manager by Pipeline 1
# =============================================================================

output "service_account_id" {
  description = "The ID of the created service account"
  value       = confluent_service_account.connector.id
}

output "service_account_name" {
  description = "The display name of the created service account"
  value       = confluent_service_account.connector.display_name
}

output "kafka_api_key" {
  description = "The Kafka API key for the connector"
  value       = confluent_api_key.connector_kafka.id
  sensitive   = true
}

output "kafka_api_secret" {
  description = "The Kafka API secret for the connector"
  value       = confluent_api_key.connector_kafka.secret
  sensitive   = true
}

# Combined output for easy injection
output "connector_credentials" {
  description = "Combined credentials object for the connector"
  value = {
    service_account_id   = confluent_service_account.connector.id
    service_account_name = confluent_service_account.connector.display_name
    kafka_api_key        = confluent_api_key.connector_kafka.id
    kafka_api_secret     = confluent_api_key.connector_kafka.secret
  }
  sensitive = true
}
