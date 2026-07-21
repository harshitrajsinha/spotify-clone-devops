# VPC for Bastion host
resource "aws_vpc" "vpc_groovify_project_bastion" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name = "${var.project_tag}-vpc"
    Project   = var.project_tag
    Terraform = "true"
  }
}

# Internet gateway for traffic from internet
resource "aws_internet_gateway" "igw_groovify_project_bastion" {
  vpc_id = aws_vpc.vpc_groovify_project_bastion.id
  tags = {
    Name = "${var.project_tag}-igw"
    Project   = var.project_tag
    Terraform = "true"
  }
}

# Public subnet for bastion host
resource "aws_subnet" "public_subnet_groovify_project_bastion" {
  vpc_id                  = aws_vpc.vpc_groovify_project_bastion.id
  availability_zone       = var.infra_azs
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_tag}-pub-sub"
    Project   = var.project_tag
    Terraform = "true"
  }
}

# route table for public subnet
resource "aws_route_table" "public_rt_groovify_project_bastion" {
  vpc_id = aws_vpc.vpc_groovify_project_bastion.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_groovify_project_bastion.id
  }
  tags = {
    Name = "${var.project_tag}-pub-rt"
    Project   = var.project_tag
    Terraform = "true"
  }
}

# route table association to public subnet
resource "aws_route_table_association" "public_rt_assn" {
  route_table_id = aws_route_table.public_rt_groovify_project_bastion.id
  subnet_id      = aws_subnet.public_subnet_groovify_project_bastion.id
}

# Security group for bastion host - will connect using ssm agent
resource "aws_security_group" "bastion_host_sg" {
  name        = "groovify-sg-bastion"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.vpc_groovify_project_bastion.id

  tags = {
    Name = "${var.project_tag}-sg"
    Project   = var.project_tag
    Terraform = "true"
  }

  egress {
    description = "Allow outbound traffic for Terraform provisioning, package installations"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}