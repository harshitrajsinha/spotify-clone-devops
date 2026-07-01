resource "aws_s3_bucket" "spotify_app_s3" {
  bucket = var.s3_bucket_name_spotify

  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }
}

resource "aws_s3_bucket_cors_configuration" "spotify_app_s3_bucket_cors" {
  bucket = aws_s3_bucket.spotify_app_s3.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET"]
    allowed_origins = ["https://${var.my_domain_name}"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_ownership_controls" "spotify_app_s3_bucket_ownership" {
  bucket = aws_s3_bucket.spotify_app_s3.id

  rule {
    object_ownership = "BucketOwnerPreferred" # Imp?
  }
}

resource "aws_s3_bucket_public_access_block" "spotify_app_s3_bucket_public_access" {
  bucket = aws_s3_bucket.spotify_app_s3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
