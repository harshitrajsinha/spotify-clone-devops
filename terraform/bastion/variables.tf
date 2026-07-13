variable "project_tag" {
  description = "Project name for which these resources are created"
  type        = string
  default     = "spotify-project-bastion"
}

variable "region" {
  description = "Region in which infrastructure exists"
  type        = string
  default     = "us-east-1"
}

variable "infra_azs" {
  description = "Availability zones for bastion host"
  type        = string
  default     = "us-east-1d"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "12.8.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "12.8.101.0/24"
}

variable "bastion_instance_type" {
  description = "Bastion server instance type"
  type        = string
  default     = "t3a.small"
}

variable "bucket_name" {
  description = "bucket name that will store app infra state file"
  type        = string
  default     = "spotify-project-remote-storage"
}