# Get existing trust policy to be used by EC2 service to assume role
data "aws_iam_policy_document" "policy_for_ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Creating a role using trust policy
resource "aws_iam_role" "ec2_role" {
  name               = "appserver-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.policy_for_ec2_assume.json
}

#################################

### Create permission policy and attach to role - For SSM Parameter store
data "aws_iam_policy_document" "permission_to_ssm_read" {
  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = [var.ssm_parameter_store_generic_arn]
  }
}
resource "aws_iam_role_policy" "attach_perm_ssm_read" {
  name   = "appserver-ssm-read-perm"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.permission_to_ssm_read.json
}

### Create permission policy and attach to role - For S3 bucket
data "aws_iam_policy_document" "permission_to_access_s3_bucket" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.spotify_app_s3.arn}/*"]
  }
}
resource "aws_iam_role_policy" "attach_perm_s3_bucket_access" {
  name   = "appserver-s3-readwrite-perm"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.permission_to_access_s3_bucket.json
}

# Using Credentials for Cognito, and DocumentDB rather than attaching permissions as latter would involve changing server code to update with AWS SDK
#################################

# Create instance profile for appserver with role to read SSM parameters
resource "aws_iam_instance_profile" "appserver_instance_profile" {
  name = "appserver-instance-profile"
  role = aws_iam_role.ec2_role.name
}


# ---------------------------------------------------------------------------------

# NOTE: It is more secure to avoid creating key-pair and access via AWS SSM
# Key pair to access app server in private subnet
resource "aws_key_pair" "spotify_appserver_key" {
  key_name   = "appserver-key"
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }
}

resource "aws_instance" "spotify_app_server" {
  ami                         = var.ubuntu_ami_id
  instance_type               = var.appserver_instance_type
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.appserver_instance_profile.name
  key_name                    = aws_key_pair.spotify_appserver_key.key_name
  subnet_id                   = element(module.vpc.private_subnets, 0) # element() performs modulo operation to avoid out of bound error
  user_data_base64            = base64encode(file("./app-server-user-data.sh"))
  vpc_security_group_ids      = [aws_security_group.spotify_appserver_sg.id]
  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }

  depends_on = [
    module.vpc,
    aws_ssm_parameter.cognito_clientid,
    aws_ssm_parameter.cognito_clientsec,
    aws_ssm_parameter.cognito_userpoolid,
    aws_ssm_parameter.vite_cognito_clientid,
    aws_ssm_parameter.docdb_connection_string
  ]
}

output "app_server_private_ip" {
  value = aws_instance.spotify_app_server.private_ip
}
