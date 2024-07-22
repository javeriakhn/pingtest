variable "acr_server_subscription" {
  type        = string
  description = "Subscription ID for the Azure Container Registry (ACR) server"
}

variable "source_acr_client_id" {
  type        = string
  description = "Client ID for the source Azure Container Registry (ACR) server"
}

variable "source_acr_server" {
  type        = string
  description = "Name of the source Azure Container Registry (ACR) server"
}

variable "acr_server" {
  type        = string
  description = "Name of the Azure Container Registry (ACR) server"
}

variable "charts" {
  type = list(object({
    chart_name       = string
    chart_namespace  = string
    chart_repository = string
    chart_version    = string
    values           = list(map(any))
  }))
  description = "List of Helm charts to be deployed"
}

variable "sensitive_values" {
  type        = list(map(any))
  description = "Sensitive values for Helm charts"
  sensitive   = true
}
