terraform {
  # 1.11 is the first release that supports write-only arguments. The route table always sets the write-only
  # `ignore_body_changes` argument to keep the routes that are managed as separate resources (see main.tf).
  required_version = ">= 1.11, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}
