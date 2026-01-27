# infra/imports.tf
import {
  to = aws_ecr_repository.your_repo_name
  id = "db-fargate-project-app"
}