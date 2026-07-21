resource "aws_security_group" "vpce" {
  name        = "vpce"
  vpc_id      = module.vpc.vpc_id
  description = "Convention security group required for VPCE endpoints referencing app server security group"

  ingress {
    description = "HTTPS from app servers"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443

    security_groups = [
      aws_security_group.groovify_appserver_sg.id
    ]
  }

  egress {
    description = "Allow all outbound traffic"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = module.vpc.private_route_table_ids

}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpce.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type = "Interface"

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpce.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type = "Interface"

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpce.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "elasticloadbalancing" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.elasticloadbalancing"
  vpc_endpoint_type = "Interface"

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpce.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpce.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type = "Interface"

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpce.id]

  private_dns_enabled = true
}