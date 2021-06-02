terraform {
  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = ">= 2.12.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.2.0"
    }
  }
}
