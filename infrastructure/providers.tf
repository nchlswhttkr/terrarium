terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.56"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.10"
    }
  }

  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "nchlswhttkr-terraform-backend"
    dynamodb_table = "nchlswhttkr-terraform-backend"
    key            = "terrarium"
    region         = "ap-southeast-4"
  }
}

provider "aws" {
  region     = "ap-southeast-2"
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
  token      = data.vault_aws_access_credentials.creds.security_token
  default_tags {
    tags = {
      Project = "Terrarium"
    }
  }
}

data "vault_aws_access_credentials" "creds" {
  backend = "aws"
  role    = "Terraform"
  type    = "sts"
}

provider "vault" {}
