module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "groovify-project"
  cidr = var.vpc_cidr

  azs                     = var.infra_azs
  private_subnets         = var.private_subnet_cidr # 3 private subnets for application server
  public_subnets          = var.public_subnet_cidr  # 3 public subnet (1 for NAT)
  intra_subnets           = var.intra_subnet_cidr   # 3 intra subnets for document DB
  map_public_ip_on_launch = false

  enable_nat_gateway = var.project_env == "production" ? true : false
  single_nat_gateway = var.project_env == "production" ? true : false
  enable_vpn_gateway = false

  tags = {
    Project   = var.project_name_tag
    Terraform = "true"
  }
}


# ------------------------------------------------------

# Separating security group resource from its rule to avoid cyclic dependency b/w SG of ALB and App Server

### Security group for ALB

resource "aws_security_group" "groovify_alb_sg" {
  name        = "groovify-alb-sg"
  description = "Allow HTTP and HTTPS inbound, and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Project   = var.project_name_tag
    Terraform = "true"
  }
}

resource "aws_security_group_rule" "sg_rule_alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  description       = "For HTTP inbound traffic"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.groovify_alb_sg.id
}

resource "aws_security_group_rule" "sg_rule_alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  description       = "For HTTPS inbound traffic"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.groovify_alb_sg.id
}

resource "aws_security_group_rule" "sg_rule_alb_egress_80" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  description              = "Forward request to Traefik reverse proxy on port 80"
  source_security_group_id = aws_security_group.groovify_appserver_sg.id
  security_group_id        = aws_security_group.groovify_alb_sg.id
}

### Security group for App server

resource "aws_security_group" "groovify_appserver_sg" {
  name        = "groovify-appserver-sg"
  description = "Allow inbound traffic from alb on 80 + SSH, and all outbound traffic for updates"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Project   = var.project_name_tag
    Terraform = "true"
  }
}

# Ingress rule to allow request to Traefik reverse proxy
resource "aws_security_group_rule" "sg_rule_appserver_ingress_80" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  description              = "Traffic on 80 for Traefik reverse proxy from ALB SG"
  source_security_group_id = aws_security_group.groovify_alb_sg.id
  security_group_id        = aws_security_group.groovify_appserver_sg.id
}

### NOTE: There is not ingress rule to connect to app server, the only way (if needed) is to connect through app server's private IP, by creating "Instance connect" VPC Endpoint, via AWS Console

# egress rule to allow outbound traffic from app server
resource "aws_security_group_rule" "sg_rule_appserver_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  description       = "Outbound to internet"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.groovify_appserver_sg.id
}


### Security group for DocumentDB
resource "aws_security_group" "groovify_docdb_sg" {
  name        = "groovify-docdb-sg"
  description = "Allow inbound traffic from appserver and bastion host on port 27017"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Project   = var.project_name_tag
    Terraform = "true"
  }
}

# Ingress rule on DocDB to allow request from app server
resource "aws_security_group_rule" "sg_rule_docdb_ingress_appserver" {
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  description              = "Inbound from app server"
  security_group_id        = aws_security_group.groovify_docdb_sg.id
  source_security_group_id = aws_security_group.groovify_appserver_sg.id
}

## Note: The only way to connect to documentdb to view records and documents (using mongosh) is through app server, as it is the only ingres rule docdb security group will accept