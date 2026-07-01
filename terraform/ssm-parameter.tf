resource "aws_ssm_parameter" "cognito_clientid" {
  name      = "/spotify/COGNITO_CLIENT_ID"
  type      = "SecureString"
  value     = aws_cognito_user_pool_client.spotify_cognito_user_pool_client.id
  overwrite = true
}

resource "aws_ssm_parameter" "cognito_clientsec" {
  name      = "/spotify/COGNITO_CLIENT_SECRET"
  type      = "SecureString"
  value     = aws_cognito_user_pool_client.spotify_cognito_user_pool_client.client_secret
  overwrite = true
}

resource "aws_ssm_parameter" "cognito_userpoolid" {
  name      = "/spotify/COGNITO_USER_POOL_ID"
  type      = "SecureString"
  value     = aws_cognito_user_pool.spotify_cognito_user_pool.id
  overwrite = true
}

resource "aws_ssm_parameter" "vite_cognito_clientid" {
  name      = "/spotify/VITE_COGNITO_CLIENT_ID"
  type      = "SecureString"
  value     = aws_cognito_user_pool_client.spotify_cognito_user_pool_client.id
  overwrite = true
}

resource "aws_ssm_parameter" "s3_bucket_spotify" {
  name      = "/spotify/S3_BUCKET_NAME"
  type      = "String"
  value     = var.s3_bucket_name_spotify
  overwrite = true
}
