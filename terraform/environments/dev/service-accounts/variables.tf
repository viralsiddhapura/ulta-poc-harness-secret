# =============================================================================
# Variables for Service Accounts Deployment (Pipeline 1)
# These are injected by Harness via TF_VAR_* environment variables
# =============================================================================

# -----------------------------------------------------------------------------
# Confluent Cloud Credentials (from Harness Secrets)
# -----------------------------------------------------------------------------

variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (injected by Harness)"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret (injected by Harness)"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Confluent Resource IDs
# -----------------------------------------------------------------------------

variable "confluent_environment_id" {
  description = "Confluent Cloud Environment ID"
  type        = string
}

variable "confluent_kafka_cluster_id" {
  description = "Confluent Cloud Kafka Cluster ID"
  type        = string
}

# -----------------------------------------------------------------------------
# Confluent Service Account Configuration
# -----------------------------------------------------------------------------

variable "confluent_service_account_name" {
  description = "Name for the Confluent service account"
  type        = string
  default     = "pubsub-connector-sa"
}

variable "connector_name" {
  description = "Name of the connector (used for documentation)"
  type        = string
  default     = "gcp-pubsub-source"
}

variable "kafka_topic" {
  description = "Target Kafka topic for the connector"
  type        = string
}

# -----------------------------------------------------------------------------
# GCP Configuration
# -----------------------------------------------------------------------------

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_bootstrap_credentials_json" {
  description = "Bootstrap GCP credentials JSON (for creating the new service account)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gcp_service_account_id" {
  description = "ID for the new GCP service account"
  type        = string
  default     = "confluent-pubsub-reader"
}

variable "gcp_service_account_display_name" {
  description = "Display name for the GCP service account"
  type        = string
  default     = "Confluent Pub/Sub Reader"
}

variable "pubsub_subscription_id" {
  description = "Pub/Sub subscription ID to grant access to"
  type        = string
}

variable "gcp_grant_project_viewer" {
  description = "Whether to grant project-level Pub/Sub viewer role"
  type        = bool
  default     = false
}
