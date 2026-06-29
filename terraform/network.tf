module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "spotify"
  cidr = var.vpc_cidr

  azs                     = var.infra_azs
  private_subnets         = var.private_subnet_cidr # 2 private subnets for application server
  public_subnets          = var.public_subnet_cidr  # 1 public subnet for NAT
  intra_subnets           = var.intra_subnet_cidr   # 3 intra subnets for document DB
  map_public_ip_on_launch = true                    # For bastion host, if provisioned

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }
}


# ------------------------------------------------------

# Separating security group resource from its rule to avoid cyclic dependency b/w SG of ALB and App Server

### Security group for ALB

resource "aws_security_group" "spotify_alb_sg" {
  name        = "spotify-alb-sg"
  description = "Allow HTTP and HTTPS inbound, and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }
}

resource "aws_security_group_rule" "sg_rule_alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  description       = "For HTTP inbound traffic"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.spotify_alb_sg.id
}

resource "aws_security_group_rule" "sg_rule_alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  description       = "For HTTPS inbound traffic"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.spotify_alb_sg.id
}

resource "aws_security_group_rule" "sg_rule_alb_egress_80" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  description              = "Forward request to Traefik reverse proxy on port 80"
  source_security_group_id = aws_security_group.spotify_appserver_sg.id
  security_group_id        = aws_security_group.spotify_alb_sg.id
}

### Security group for App server

resource "aws_security_group" "spotify_appserver_sg" {
  name        = "spotify-appserver-sg"
  description = "Allow inbound traffic from alb on 80 + SSH, and all outbound traffic for updates"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }
}

# Ingress rule to allow request to Traefik reverse proxy
resource "aws_security_group_rule" "sg_rule_appserver_ingress_80" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  description              = "Traffic on 80 for Traefik reverse proxy from ALB SG"
  source_security_group_id = aws_security_group.spotify_alb_sg.id
  security_group_id        = aws_security_group.spotify_appserver_sg.id
}

# Ingress rule to allow SSH request
resource "aws_security_group_rule" "sg_rule_appserver_ingress_22" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  description              = "Traffic on 22 from Bastion SG"
  source_security_group_id = aws_security_group.bastion_host_sg.id
  security_group_id        = aws_security_group.spotify_appserver_sg.id
}


resource "aws_security_group_rule" "sg_rule_appserver_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  description       = "Outbound to internet"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.spotify_appserver_sg.id
}