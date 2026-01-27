# bootstrap/main.tf
provider "aws" {
  region = "us-east-1" # Update to your region
}

terraform {
  required_version = ">= 1.10.0" # Required for native S3 locking
  
  backend "s3" {
    bucket       = "my-new-ecs-project-state-2026"
    key          = "bootstrap/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # <--- This replaces DynamoDB!
  }
}

# 1. REFERENCE THE EXISTING OIDC PROVIDER
# This looks up the provider you already created in your other project.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# 2. CREATE THE S3 BUCKET (With Native Locking)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-new-ecs-project-state-2026" # Change this to be unique

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration { status = "Enabled" }
}

# 3. CREATE THE PROJECT-SPECIFIC ROLE
resource "aws_iam_role" "github_actions" {
  name = "ecs-fargate-project-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            # Replace with your actual Repo path
            "token.actions.githubusercontent.com:sub": "repo:sprakriy/db-fargate-project:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# 4. ATTACH ADMIN PERMISSIONS (Required for Initial Build)
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}