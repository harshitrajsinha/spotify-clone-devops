variable "region" {
  description = "Region in which infrastructure exists"
  type        = string
  default     = "us-east-1"
}

variable "project_name_tag" {
  description = "Name of the project for which infrastructure is being provisioned"
  type        = string
  default     = "spotify-project"
}

variable "project_env" {
  description = "Env of the project for which infrastructure is being provisioned"
  type        = string
}

variable "infra_azs" {
  description = "Availability zones list"
  type        = list(string)
  default     = ["us-east-1d", "us-east-1e", "us-east-1f"]
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.5.0.0/16"
}

variable "private_subnet_cidr" {
  description = "List of CIDR blocks for private subnet"
  type        = list(string)
  default     = ["10.5.1.0/24", "10.5.2.0/24", "10.5.3.0/24"]
}

variable "public_subnet_cidr" {
  description = "List of CIDR blocks for public subnet"
  type        = list(string)
  default     = ["10.5.101.0/24", "10.5.102.0/24", "10.5.103.0/24"]
}

variable "intra_subnet_cidr" {
  description = "List of CIDR blocks for intra subnet"
  type        = list(string)
  default     = ["10.5.11.0/24", "10.5.12.0/24", "10.5.13.0/24"]
}

variable "bastion_host_sg_name" {
  deprecated = "name of the bastion host security group that will be imported for reference"
  type       = string
  default    = "spotify-sg-bastion"
}

variable "custom_dev_ubuntu_ami_id" {
  description = "Custom ubuntu-based AMI for development"
  type        = string
  default     = "ami-0727c2162ec7e3faa"
}

variable "sonarqube_image" {
  default = "sonarqube:lts-community"
}

variable "appserver_instance_type" {
  description = "App server instance type"
  type        = string
  default     = "t3a.medium"
}

variable "ssm_parameter_store_generic_arn" {
  description = "ARN with wildcard that includes all the parameters store on SSM parameter store"
  type        = string
  default     = "arn:aws:ssm:us-east-1:211125424910:parameter/spotify/*"
}

variable "alb_listener_ssl_policy" {
  description = "SSL policy value for ALB listener at port 443"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
}

variable "my_domain_name" {
  description = "My custom domain name"
  type        = string
  default     = "harshitrajsinha.fun"
}

variable "cognito_domain" {
  description = "Domain name for cognito"
  type        = string
  default     = "auth.harshitrajsinha.fun"
}

variable "s3_bucket_name_spotify" {
  description = "S3 bucket name for spotify app"
  type        = string
  default     = "spotify-app-object-store"
}

variable "docdb_master_username" {
  description = "Master username for docdb"
  type        = string
  sensitive   = true
}

variable "remote_backend_bucket_name" {
  description = "S3 bucket name to store terraform state file"
  type        = string
  default     = "spotify-project-terraform-state"
}

variable "remote_backend_bucket_key" {
  description = "S3 bucket key for remote backend"
  type        = string
  default     = "spotify/terraform.tfstate"
}

#################################

variable "google_client_id" {
  type = string
  # default   = "null"
  sensitive = true
  # NOTE: The default value is explicitly commented to apply failure and enforce passing value for variable through command line
}
variable "google_client_secret" {
  type = string
  # default   = "null"
  sensitive = true
  # NOTE: The default value is explicitly commented to apply failure and enforce passing value for variable through command line
}