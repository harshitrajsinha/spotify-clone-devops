#########################
#
# IMP NOTE: This for development and that is why full access is provided, in production custom policy needs to be created as per the requirements to achieve least-privilege policy
#
#########################



# Trust policy - allows bastion host to assume the role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Role
resource "aws_iam_role" "bastion_iam_role" {
  name               = "bastion-iam-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

### IMP NOTE: There is a limit to 10 policies per role, and an instance profile can only have one role attached to it.

# Combined policy for VPC/IAM/EC2/ELB/S3/DocumentDB/ACM FullAccess managed policies
resource "aws_iam_policy" "bastion_aws_managed_equivalent" {
  name        = "bastion-aws-managed-equivalent-policy"
  description = "Combined full-access permissions equivalent to VPC, IAM, EC2, ELB, S3, DocumentDB, and ACM AWS-managed policies"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2AndVPCFullAccess"
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMFullAccess"
        Effect = "Allow"
        Action = [
          "iam:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "ELBFullAccess"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3FullAccess"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "DocumentDBFullAccess"
        Effect = "Allow"
        Action = [
          "docdb:*",
          "rds:Describe*",
          "rds:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "ACMFullAccess"
        Effect = "Allow"
        Action = [
          "acm:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_aws_managed_equivalent" {
  role       = aws_iam_role.bastion_iam_role.name
  policy_arn = aws_iam_policy.bastion_aws_managed_equivalent.arn
}

# Attach AWS-managed Cognito policy
resource "aws_iam_role_policy_attachment" "cognito_access" {
  role       = aws_iam_role.bastion_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoPowerUser"
}

# Attach EC2 SSM agent IAM role for access
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.bastion_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Combined custom policy: SSM/KMS/Secrets Manager + additional Terraform permissions
resource "aws_iam_policy" "bastion_custom_policy" {
  name        = "bastion-custom-policy"
  description = "Combined SSM, KMS, Secrets Manager, Cognito custom domain, and DocumentDB permissions for bastion instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSM"
        Effect = "Allow"
        Action = [
          "ssm:*",
          "ssmmessages:*",
          "ec2messages:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "SecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "KMS"
        Effect = "Allow"
        Action = [
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:ListAliases",
          "kms:ListKeys"
        ]
        Resource = "*"
      },
      {
        Sid    = "CognitoCustomDomain"
        Effect = "Allow"
        Action = [
          "cognito-idp:*",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:UpdateDistribution",
          "cloudfront:TagResource",
          "cloudfront:UntagResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "DocumentDBRead"
        Effect = "Allow"
        Action = [
          "rds:DescribeGlobalClusters",
          "rds:CreateDBSubnetGroup",
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "rds:DescribeDBSubnetGroups",
          "rds:DescribeDBClusterParameterGroups",
          "rds:DescribeDBClusterParameters",
          "rds:DescribeDBEngineVersions",
          "rds:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "DocumentDBWrite"
        Effect = "Allow"
        Action = [
          "rds:CreateDBCluster",
          "rds:DeleteDBCluster",
          "rds:DeleteDBSubnetGroup",
          "rds:ModifyDBCluster",
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:ModifyDBInstance",
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_custom_policy" {
  role       = aws_iam_role.bastion_iam_role.name
  policy_arn = aws_iam_policy.bastion_custom_policy.arn
}

########################################

# Instance Profile
resource "aws_iam_instance_profile" "terraform_bastion_profile" {
  name = "terraform-bastion-profile"
  role = aws_iam_role.bastion_iam_role.name
}

# ----------------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create bastion host (EC2) - will connect using SSM agent
resource "aws_instance" "groovify_bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.bastion_instance_type
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.terraform_bastion_profile.name
  subnet_id                   = aws_subnet.public_subnet_groovify_project_bastion.id
  user_data_base64            = base64encode(file("./bastion-user-data.sh"))
  vpc_security_group_ids      = [aws_security_group.bastion_host_sg.id]
  tags = {
    Name = "${var.project_tag}-instance"
    Project   = var.project_tag
    Terraform = "true"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }
}

output "bastion_public_ip" {
  value = aws_instance.groovify_bastion.public_ip
}

output "bastion_instance_id" {
  value = aws_instance.groovify_bastion.id
}
