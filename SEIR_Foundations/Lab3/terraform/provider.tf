# Tokyo provider (default)
provider "aws" {
  region = var.shinjuku_az
}

# Sao Paulo provider
provider "aws" {
  alias  = "saopaulo"
  region = var.liberdade_az
}
