# terraform.tfvars — Variable Value Overrides
#
# This file overrides the defaults set in variables.tf.
# Terraform automatically loads this file if it is named exactly terraform.tfvars
#
# For environment-specific overrides, create named files:
#   prod.tfvars, staging.tfvars, dev.tfvars
# And pass them at runtime:
#   terraform apply -var-file="prod.tfvars"
#
# IMPORTANT: Add this file to .gitignore if it contains sensitive values.

instance_type = "t2.large"
vpn_ip        = "116.30.45.50/32"
