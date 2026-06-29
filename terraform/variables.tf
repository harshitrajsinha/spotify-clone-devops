variable "region" {
  description = "Region in which infrastructure exists"
  type        = string
  default     = "us-east-1"
}

variable "project_name_tag" {
  description = "Name of the project for which infrastructure is being provisioned"
  type        = string
  default     = "spotify"
}

variable "project_env_tag" {
  description = "Environment of the project for which infrastructure is being provisioned"
  type        = string
  default     = "dev"
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
  default     = ["10.5.1.0/24", "10.5.2.0/24"]
}

variable "public_subnet_cidr" {
  description = "List of CIDR blocks for public subnet"
  type        = list(string)
  default     = ["10.5.101.0/24", "10.5.102.0/24"]
}

variable "intra_subnet_cidr" {
  description = "List of CIDR blocks for intra subnet"
  type        = list(string)
  default     = ["10.5.11.0/24", "10.5.12.0/24"]
}

variable "ubuntu_ami_id" {
  description = "AMI of Ubuntu 24.04"
  type        = string
  default     = "ami-0f8a61b66d1accaee"
}

variable "appserver_instance_type" {
  description = "App server instance type"
  type        = string
  default     = "t3a.medium"
}

variable "bastion_instance_type" {
  description = "Bastion server instance type"
  type        = string
  default     = "t3a.micro"
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