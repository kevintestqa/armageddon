variable "shinjuku_az" {
  description = "Tokyo"
  type        = string
  default     = "ap-northeast-1"
}

variable "liberdade" {
  default = "liberdade"
}

variable "liberdade_region" {
  description = "saopaulo"
  type        = string
  default     = "sa-east-1"
}

variable "liberdade_vpc" {
  description = "Sao Pualo VPC CIDR"
  type        = string
  default     = "10.20.0.0/16"
}

variable "liberdade_public_cidrs" {
  description = "Public subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "liberdade_private_cidrs" {
  description = "Private subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "shinjuku_vpc" {
  description = "Tokyo VPC CIDR"
  type        = string
  default     = "10.30.0.0/16"
}

variable "shinjuku_private_cidrs" {
  description = "Private subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.30.11.0/24", "10.30.12.0/24"]
}

variable "asg_minimum_size" {
  description = "Auto Scaling Group minimum size."
  type        = number
  default     = 2
}

variable "asg_maximum_size" {
  description = "Auto Scaling Group maximum size."
  type        = number
  default     = 5
}

variable "asg_desired_capacity" {
  description = "Auto Scaling Group desired capacity."
  type        = number
  default     = 3
}

variable "ec2_instance_type" {
  description = "EC2 instance size for the app."
  type        = string
  default     = "t3.micro"
}

variable "origin_header_name" {
  description = "Header name for Sao Paulo environment"
  type        = string
  default     = "X-liberdade-verification"
}

variable "origin_header_value" {
  description = "Value for Sao Paulo environment"
  type        = string
  default     = "liberdade-origin"
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 app host."
  type        = string
  default     = "ami-025f404fafb21297b"
}

variable "liberdade_azs" {
  description = "Availability Zones list (match count with subnets)."
  type        = list(string)
  default     = ["sa-east-1a", "sa-east-1b"]
}

variable "shinjuku_peer_attachment_id" {
  type = string
}

variable "db_name" {
  type  = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "shinjuku_rds_endpoint" {
  description = "Tokyo RDS endpoint passed into the Sao Paulo stack"
  type        = string
}

variable "shinjuku_rds_port" {
  description = "Tokyo RDS port passed into the Sao Paulo stack"
  type        = number
}