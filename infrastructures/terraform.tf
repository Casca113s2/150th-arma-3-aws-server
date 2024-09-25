terraform {
#   backend "s3" {
#     bucket = "casca-aws-terraform-state"
#     key    = "prod/aws_infra"
#     region = "ap-southeast-1"

#     dynamodb_table = "casca-terraform-locks"
#     encrypt = true
#   }

  required_providers {
    aws = {
      version = "~> 5.66.0"
    }
    random = {
      version = "~> 3.6.2"
    }
  }

  required_version = "~> 1.9.5"
}