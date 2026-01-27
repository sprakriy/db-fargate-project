# 1. Create the Private DNS Zone (only visible inside your VPC)
resource "aws_service_discovery_private_dns_namespace" "db_zone" {
  name        = "database.local"
  description = "Internal service discovery for my Fargate DB"
  vpc         = aws_vpc.main.id  # Make sure this matches your VPC resource name
}

# 2. Register the specific Database Service name
resource "aws_service_discovery_service" "postgres_dns" {
  name = "postgres"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.db_zone.id
    
    dns_records {
      ttl  = 60
      type = "A"
    }
  }

  # This helps AWS clean up old IPs quickly if a task restarts
#  health_check_custom_config {
#    failure_threshold = 1
#  }
}