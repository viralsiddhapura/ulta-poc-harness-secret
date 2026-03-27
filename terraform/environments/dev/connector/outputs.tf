# =============================================================================
# Outputs for Connector Deployment (Pipeline 2)
# =============================================================================

output "connector_id" {
  description = "ID of the deployed connector"
  value       = module.gcp_pubsub_connector.connector_id
}

output "connector_name" {
  description = "Name of the deployed connector"
  value       = module.gcp_pubsub_connector.connector_name
}

output "connector_status" {
  description = "Status of the connector"
  value       = module.gcp_pubsub_connector.connector_status
}

output "deployment_info" {
  description = "Deployment information summary"
  value = {
    connector_id           = module.gcp_pubsub_connector.connector_id
    connector_name         = module.gcp_pubsub_connector.connector_name
    kafka_topic            = var.kafka_topic
    gcp_project_id         = var.gcp_project_id
    pubsub_subscription_id = var.pubsub_subscription_id
    environment_id         = var.confluent_environment_id
    cluster_id             = var.confluent_kafka_cluster_id
  }
}
