# infra/imports.tf
import {
  to = aws_ecr_repository.app
  id = "db-fargate-project-app"
}