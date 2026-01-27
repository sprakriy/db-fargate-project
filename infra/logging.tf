resource "aws_cloudwatch_log_group" "postgres" {
  name              = "/ecs/postgres-db"
  retention_in_days = 1
}