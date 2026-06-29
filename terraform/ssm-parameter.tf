# Store Cognito client id (for backend service)
resource "aws_ssm_parameter" "cognito_clientid" {
  name  = "/spotify/COGNITO_CLIENT_ID"
  type  = "SecureString"
  value = aws_cognito_user_pool_client.spotify_cognito_user_pool_client.id
}

# Store Cognito client secret
resource "aws_ssm_parameter" "cognito_clientsec" {
  name  = "/spotify/COGNITO_CLIENT_SECRET"
  type  = "SecureString"
  value = aws_cognito_user_pool_client.spotify_cognito_user_pool_client.client_secret
}

# Store Cognito user pool id
resource "aws_ssm_parameter" "cognito_userpoolid" {
  name  = "/spotify/COGNITO_USER_POOL_ID"
  type  = "SecureString"
  value = aws_cognito_user_pool.spotify_cognito_user_pool.id
}


# Store Cognito client id (for frontend service)
resource "aws_ssm_parameter" "vite_cognito_clientid" {
  name  = "/spotify/VITE_COGNITO_CLIENT_ID"
  type  = "SecureString"
  value = aws_cognito_user_pool_client.spotify_cognito_user_pool_client.id
}
