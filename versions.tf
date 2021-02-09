terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      version = "=> 3.5.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.6.2"
    }
    kubernetes = {
      version = "=> 1.13"
    }
  }
}
