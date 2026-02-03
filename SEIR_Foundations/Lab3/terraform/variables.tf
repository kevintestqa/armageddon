variable "shinjuku_az" {
  description = "Tokyo"
  type        = string
  default     = "ap-northeast-1"
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
