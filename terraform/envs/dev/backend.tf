terraform {
  # Default: Local state (works out of the box)
  # For remote state with S3, see README.md "Approach B: Production Setup"
  backend "local" {
    path = "terraform.tfstate"
  }
}

