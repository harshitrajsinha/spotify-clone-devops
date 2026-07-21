# S3 bucket that 
resource "aws_s3_bucket" "app_infra_remote_storage" {
  bucket        = var.bucket_name
  force_destroy = true
  tags = {
    Name = "${var.project_tag}-s3-bucket"
    Project   = var.project_tag
    Terraform = "true"
  }
}

resource "aws_s3_bucket_versioning" "app_infra_remote_storage_versioning" {
  bucket = aws_s3_bucket.app_infra_remote_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_infra_remote_storage_encrypt" {
  bucket = aws_s3_bucket.app_infra_remote_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_infra_remote_storage_access" {
  bucket                  = aws_s3_bucket.app_infra_remote_storage.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}