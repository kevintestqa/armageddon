variable "gcp_project_id" { type = string }
variable "gcp_region"     { type = string  default = "us-central1" }

# Students provide these
variable "nihonmachi_vpc_cidr"     { type = string  default = "10.x.x.x/xx" }
variable "nihonmachi_subnet_cidr"  { type = string  default = "10.x.x.x/xx" }

# Who is allowed to access the NY private URL (VPN/TGW subnets)
variable "allowed_vpn_cidrs" {
  type    = list(string)
  default = ["10.x.x.x/xx"] # students: add AWS Tokyo VPC CIDR, corp VPN CIDR, etc.
}

# Tokyo RDS endpoint (private resolvable/reachable over VPN)
variable "tokyo_rds_host" { type = string  default = "tokyo-rds-endpoint.example" }
variable "tokyo_rds_port" { type = number  default = 3306 }

# DB user is OK to store as plain var; password should not be in TF state (use Secret Manager)
variable "tokyo_rds_user" { type = string  default = "appuser" }

# Secret name holding DB password (created outside TF or by TF—your choice)
variable "db_password_secret_name" { type = string  default = "nihonmachi-tokyo-rds-password" }
