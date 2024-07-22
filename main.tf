terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {
  subscription_id = var.acr_server_subscription
}

resource "azurerm_resource_group" "chart_import_rg" {
  name     = "chart-import-rg"
  location = "West Europe"
}

resource "azurerm_role_assignment" "copy_role" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = "7f951dda-4ed3-4680-a7ca-43fe172d538d" # AcrPush
  principal_id       = var.source_acr_client_id
}

resource "null_resource" "copy_charts" {
  provisioner "local-exec" {
    command = <<-EOT
      az acr login --name ${var.source_acr_server}
      az acr login --name ${var.acr_server}
      for chart in ${jsonencode(var.charts)}; do
        chart_name=$(echo $chart | jq -r ".chart_name")
        chart_namespace=$(echo $chart | jq -r ".chart_namespace")
        chart_repository=$(echo $chart | jq -r ".chart_repository")
        chart_version=$(echo $chart | jq -r ".chart_version")
        az acr helm pull --name $chart_name --version $chart_version --repository $chart_repository --host ${var.source_acr_server}
        az acr helm push --name $chart_name --version $chart_version --repository $chart_namespace --host ${var.acr_server}
      done
    EOT
  }

  triggers = {
    charts = jsonencode(var.charts)
  }
}

resource "helm_release" "chart_install" {
  count         = length(var.charts)
  name          = var.charts[count.index].chart_name
  namespace     = var.charts[count.index].chart_namespace
  repository    = "https://${var.acr_server}/helm/v1/repo"
  chart         = var.charts[count.index].chart_name
  version       = var.charts[count.index].chart_version
  values        = [for v in var.charts[count.index].values : "${jsonencode(v)}"]

  dynamic "set_sensitive" {
    for_each = var.sensitive_values[count.index]
    content {
      name  = set_sensitive.key
      value = set_sensitive.value
    }
  }
}
