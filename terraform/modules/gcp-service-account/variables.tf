# =============================================================================
# Variables for GCP Service Account Module
# =============================================================================

variable "gcp_project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.gcp_project_id))
    error_message = "GCP project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens"
  }
}

variable "service_account_id" {
  description = "The service account ID (must be unique within the project, 6-30 characters)"
  type        = string
  default     = "confluent-pubsub-reader"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.service_account_id))
    error_message = "Service account ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens"
  }
}

variable "service_account_display_name" {
  description = "Display name for the service account"
  type        = string
  default     = "Confluent Pub/Sub Reader"
}

variable "pubsub_subscription_id" {
  description = "The Pub/Sub subscription ID to grant access to (optional - leave empty to skip subscription-level binding)"
  type        = string
  default     = ""
}

variable "grant_project_viewer" {
  description = "Whether to grant project-level Pub/Sub viewer role (required if subscription ID not known at creation time)"
  type        = bool
  default     = false
}
