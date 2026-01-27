resource "aws_ecs_cluster" "main" {
  name = "db-project-cluster"
}

resource "aws_ecs_task_definition" "postgres" {
  family                   = "postgres-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn# THE FIX: This gives the container 10 minutes to finish initdb 


  container_definitions = jsonencode([{
    name      = "postgres"
    image     = "319310747432.dkr.ecr.us-east-1.amazonaws.com/db-fargate-project-app:latest"
    essential = true
# 1. THE SMOKING GUN: Force the container to run as the postgres user
  # This prevents the 'started under privileged user' error from the binary
  user = "0" 

  entryPoint = ["sh", "-c"]

command = [
  <<-EOT
  # Step 1: Prep folders
  mkdir -p /local_pgdata /var/lib/postgresql/data/efs_storage
  chown -R postgres:postgres /local_pgdata /var/lib/postgresql/data
  
  # Step 2: Initialize if empty
  if [ ! -s /local_pgdata/PG_VERSION ]; then
    su-exec postgres initdb --no-sync -D /local_pgdata
    
    # --- NEW: OPEN THE SECURITY GATES ---
    # Allow all IPs to connect (Trust AWS Security Groups to do the heavy filtering)
    echo "host all all 0.0.0.0/0 md5" >> /local_pgdata/pg_hba.conf
    # Listen on all network interfaces
    echo "listen_addresses='*'" >> /local_pgdata/postgresql.conf
    # ------------------------------------

    mv /local_pgdata/base /var/lib/postgresql/data/efs_storage/
    mv /local_pgdata/pg_wal /var/lib/postgresql/data/efs_storage/
  fi

  ln -s /var/lib/postgresql/data/efs_storage/base /local_pgdata/base
  ln -s /var/lib/postgresql/data/efs_storage/pg_wal /local_pgdata/pg_wal
  
  # NEW: Force the password to match the current Environment Variable
  # This works even if the data already exists on EFS.
  #postgres --single -D /local_pgdata <<< "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASSWORD';"
  # Replace the old line with this one:
  echo "ALTER USER postgres WITH PASSWORD 'password123';" | su-exec postgres postgres --single -D /local_pgdata

  # Start the engine as usual
  exec su-exec postgres postgres -D /local_pgdata
  EOT
]
    portMappings = [{
      containerPort = 5432
      hostPort      = 5432
    }]
    environment = [
      { name = "POSTGRES_PASSWORD", value = "mysecurepassword" },    # Change this!
      { name = "PGDATA", value = "/var/lib/postgresql/data/pgdata" }
      ]
      mountPoints = [{
      sourceVolume  = "postgres-storage"
      containerPath = "/var/lib/postgresql/data"
      readOnly      = false
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/postgres-db"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
  
    volume {
    name = "postgres-storage"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.postgres_data.id
      transit_encryption      = "ENABLED" # Required for Access Points
      authorization_config {
        access_point_id = aws_efs_access_point.postgres.id
        iam             = "DISABLED"
      }
      root_directory = "/"
    }
  }

}

resource "aws_ecs_service" "main" {
  name            = "postgres-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.postgres.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  # before AWS starts judging its health.
  health_check_grace_period_seconds = 600

# This is crucial: Don't start the DB until the "plugs" are ready
/*
  depends_on = [
    aws_efs_mount_target.target_1,
    aws_efs_mount_target.target_2
  ]
  */
  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.db_sg.id]
    assign_public_ip = true
  }
  service_registries {
    registry_arn = aws_service_discovery_service.postgres_dns.arn
  }
}