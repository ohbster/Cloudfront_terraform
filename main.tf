terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

# Terraform statefile bucket
terraform {
  backend "s3" {
    bucket = "ohbster-ado-terraform-class5" # Change this to your own terraform state s3 bucket
    key    = "cloudfront/terraform.tfstate"
    region = "us-east-1"
  }
}

# Extra stuff. Not really necessary. you can ignore this
# This is used by resource tags. This is will identify all resources that belong to the terraform deployment
resource "random_uuid" "uuid" {
}

locals {
  common_tags = merge(var.common_tags, { mff_id = random_uuid.uuid.result })
}
