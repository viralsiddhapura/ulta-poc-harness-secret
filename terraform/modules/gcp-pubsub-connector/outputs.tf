# =============================================================================
# Outputs for GCP Pub/Sub Source Connector Module
# =============================================================================

output "connector_id" {
  description = "The ID of the created connector"
  value       = confluent_connector.gcp_pubsub_source.id
}

output "connector_name" {
  description = "The name of the connector"
  value       = var.connector_name
}

output "connector_status" {
  description = "The status of the connector"
  value       = confluent_connector.gcp_pubsub_source.status
}

output "connector_config" {
  description = "Non-sensitive connector configuration"
  value = {
    name                   = var.connector_name
    kafka_topic            = var.kafka_topic
    gcp_project_id         = var.gcp_project_id
    pubsub_subscription_id = var.pubsub_subscription_id
    tasks_max              = var.tasks_max
    output_data_format     = var.output_data_format
  }
}
