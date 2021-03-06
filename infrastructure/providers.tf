terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.56.0"
    }

    pass = {
      source  = "nicholas.cloud/nchlswhttkr/pass"
      version = ">= 0.1"
    }
  }

  required_version = ">= 1.0"

  backend "local" {
    path = "/Users/nchlswhttkr/Google Drive/terraform/terrarium.tfstate"
  }
}

provider "aws" {
  region     = "ap-southeast-2"
  access_key = data.pass_password.aws_access_key_id.password
  secret_key = data.pass_password.aws_access_key_secret.password
  default_tags {
    tags = {
      Project = "terraria.nicholas.cloud"
    }
  }
}

data "pass_password" "aws_access_key_id" {
  name = "website/aws-access-key-id"
}

data "pass_password" "aws_access_key_secret" {
  name = "website/aws-access-key-secret"
}
provider "pass" {
  store = "/Users/nchlswhttkr/Google Drive/.password-store"
}
