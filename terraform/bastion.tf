# Trust policy - allows EC2 to assume the role
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

# Attach AWS-managed AdministratorAccess policy
resource "aws_iam_role_policy_attachment" "administrator_access" {
  role       = aws_iam_role.bastion_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# Instance Profile
resource "aws_iam_instance_profile" "terraform_bastion_profile" {
  name = "terraform-bastion-profile"
  role = aws_iam_role.bastion_iam_role.name
}

# ----------------------------------------------------------------------

# This will not work in Github Actions
# data "http" "my_ip" {
#  url = "https://checkip.amazonaws.com"
# }

# Security group for bastion host

resource "aws_security_group" "bastion_host_sg" {
  name        = "spotify-sg-bastion"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

}

resource "aws_key_pair" "spotify_bastion_key" {
  key_name   = "bastion-key"
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }
}

resource "aws_instance" "spotify_bastion" {
  ami                         = var.ubuntu_ami_id
  instance_type               = var.bastion_instance_type
  associate_public_ip_address = true
  # iam_instance_profile = ? # so that terraform can create resources on aws without requirement of installing aws cli and configuring with keys
  key_name               = aws_key_pair.spotify_bastion_key.key_name
  subnet_id              = element(module.vpc.public_subnets, 0)
  user_data_base64       = base64encode(file("./bastion-user-data.sh"))
  vpc_security_group_ids = [aws_security_group.bastion_host_sg.id]
  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }
}

output "bastion_public_ip" {
  value = aws_instance.spotify_bastion.public_ip
}