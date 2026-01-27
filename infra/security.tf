
resource "aws_security_group" "db_sg" {
  name        = "postgres-sg"
  description = "Allow inbound traffic to Postgres"
  vpc_id      = aws_vpc.main.id

  # Inbound: Allow Postgres from anywhere (for now, for testing)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Outbound: Allow everything (Needed to pull images from ECR)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.db_sg.id] # Allow DB to talk to EFS
  }
}