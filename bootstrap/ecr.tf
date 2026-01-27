resource "aws_ecr_repository" "app" {
  # Change this to a unique name for this project
  name                 = "db-fargate-project-app" 
  image_tag_mutability = "MUTABLE"

  force_delete = true # Allows Terraform to delete the repo even if it contains images

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "repository_url" {
  value = aws_ecr_repository.app.repository_url
}