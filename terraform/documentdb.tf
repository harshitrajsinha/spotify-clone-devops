# Subnet group
resource "aws_docdb_subnet_group" "spotify_docdb_subnet_grp" {
  name       = "spotify-docdb-subnet-grp"
  subnet_ids = module.vpc.intra_subnets

  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }
}

# Cluster
resource "aws_docdb_cluster" "spotify_docdb" {
  cluster_identifier          = "spotify-docdb-cluster"
  engine                      = "docdb"
  availability_zones          = module.vpc.azs
  apply_immediately           = false
  db_subnet_group_name        = aws_docdb_subnet_group.spotify_docdb_subnet_grp.name
  master_username             = var.docdb_master_username
  manage_master_user_password = true
  network_type                = "IPV4"
  port                        = 27017
  backup_retention_period     = 1
  preferred_backup_window     = "12:00-01:00"
  skip_final_snapshot         = true
  vpc_security_group_ids      = [aws_security_group.spotify_docdb_sg.id]
  tags = {
    Project     = var.project_name_tag
    Terraform   = "true"
    Environment = var.project_env_tag
  }

}

# Cluster instance for write operations (primary)
resource "aws_docdb_cluster_instance" "spotify_docdb_writer" {
  identifier         = "spotify-docdb-writer"
  cluster_identifier = aws_docdb_cluster.spotify_docdb.id
  instance_class     = "db.t3.medium"
  apply_immediately  = false

  tags = {
    Project     = var.project_name_tag
    Terraform   = "true"
    Environment = var.project_env_tag
  }
}

# Cluster instance for read operations (replica)
resource "aws_docdb_cluster_instance" "spotify_docdb_reader" {
  identifier         = "spotify-docdb-reader"
  cluster_identifier = aws_docdb_cluster.spotify_docdb.id
  instance_class     = "db.t3.medium"
  apply_immediately  = false

  tags = {
    Project     = var.project_name_tag
    Terraform   = "true"
    Environment = var.project_env_tag
  }
}

##################################

# Build connection string for database to be used by backend application

data "aws_secretsmanager_secret_version" "docdb_password" {
  secret_id = aws_docdb_cluster.spotify_docdb.master_user_secret[0].secret_arn
}

locals {
  docdb_creds             = jsondecode(data.aws_secretsmanager_secret_version.docdb_password.secret_string)
  docdb_connection_string = "mongodb://${urlencode(local.docdb_creds.username)}:${urlencode(local.docdb_creds.password)}@${aws_docdb_cluster.spotify_docdb.endpoint}:27017/spotify?replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false&tls=true&authMechanism=SCRAM-SHA-1&authSource=admin"
}

resource "aws_ssm_parameter" "docdb_connection_string" {
  name      = "/spotify/MONGODB_URI"
  type      = "SecureString"
  value     = local.docdb_connection_string
  overwrite = true
}