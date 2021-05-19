terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      version = ">= 3.5.0"
    }
    kubernetes = {
      version = ">= 1.13"
    }
  }
}
