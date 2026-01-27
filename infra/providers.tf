terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    # This must match the bucket you created in the bootstrap phase
    bucket         = "my-new-ecs-project-state-2026" 
    key            = "infrastructure/terraform.tfstate" # Different key than bootstrap
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true # Native S3 locking (No DynamoDB needed!)
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}