variable "shinjuku_az" {
  description = "Tokyo"
  type        = string
  default     = "ap-northeast-1"
}

variable "liberdade" {
  default = "liberdade"
}

variable "liberdade_az" {
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

variable "shinjuku_public_cidrs" {
  description = "Public subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.30.1.0/24", "10.30.2.0/24"]
}

variable "db_engine" {
  description = "RDS engine."
  type        = string
  default     = "mysql"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "elysium"
}

variable "db_username" {
  description = "DB master username (students should use Secrets Manager in 1B/1C)."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "DB master password (DO NOT hardcode in real life; for lab only)."
  type        = string
  sensitive   = true
  default     = "Quasar123!"
}

variable "storage_type" {
  description = "RDS storage type (gp3 recommended)."
  type        = string
  default     = "gp3"
}