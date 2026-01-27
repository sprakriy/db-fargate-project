/* 
#Because don't want to get created again before we didn't remove # The File System
resource "aws_efs_file_system" "postgres_data" {
  creation_token = "postgres-data"
  encrypted      = true
  tags           = { Name = "postgres-efs" }
}

# Mount Target for Subnet 1
resource "aws_efs_mount_target" "target_1" {
  file_system_id  = aws_efs_file_system.postgres_data.id
  subnet_id       = aws_subnet.public_1.id
  security_groups = [aws_security_group.efs_sg.id]
}

# Mount Target for Subnet 2
resource "aws_efs_mount_target" "target_2" {
  file_system_id  = aws_efs_file_system.postgres_data.id
  subnet_id       = aws_subnet.public_2.id
  security_groups = [aws_security_group.efs_sg.id]
}
resource "aws_efs_access_point" "postgres" {
  file_system_id = aws_efs_file_system.postgres_data.id

  # This ensures the /postgres directory exists and is owned by postgres user (999)
  root_directory {
    path = "/postgres"
    creation_info {
      owner_gid   = 999
      owner_uid   = 999
      permissions = "755"
    }
  }

  # This forces the Fargate task to act as the postgres user
  posix_user {
    gid = 999
    uid = 999
  }
}
*/