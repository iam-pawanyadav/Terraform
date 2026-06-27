# Example 01 — Your First EC2 Instance
#
# This is the simplest possible Terraform configuration.
# It creates one EC2 instance on AWS using static credentials.
#
# HOW TO USE:
#   1. Replace access_key and secret_key with your AWS IAM credentials
#   2. Run: terraform init
#   3. Run: terraform plan
#   4. Run: terraform apply
#   5. Run: terraform destroy  (when done)
#
# NOTE: Hardcoded credentials are for learning only. In production,
# use environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
# or IAM instance roles.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# -----------------------------------------------------------------------
# PROVIDER BLOCK
# Answers: What platform? Which region? How do we authenticate?
# -----------------------------------------------------------------------
provider "aws" {
  region     = "us-west-2"
  access_key = "YOUR_ACCESS_KEY_HERE"   # Replace or use env variable
  secret_key = "YOUR_SECRET_KEY_HERE"   # Replace or use env variable
}

# -----------------------------------------------------------------------
# RESOURCE BLOCK
# Answers: What resource do we want? What are its minimum required settings?
# -----------------------------------------------------------------------
resource "aws_instance" "my_ec2" {
  # Mandatory for EC2:
  ami           = "ami-05b622b5fa0269787"   # Amazon Linux 2 in us-west-2
  instance_type = "t2.micro"                # Free tier eligible

  # Everything else is optional — Terraform will use AWS defaults.
  # Run `terraform plan` to see all the fields that are "known after apply".
}
