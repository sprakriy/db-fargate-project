# In infra/main.tf
data "aws_ecr_repository" "app" {
  name = "db-fargate-project-app"
}

# Then you reference it like this:
# data.aws_ecr_repository.app.repository_url