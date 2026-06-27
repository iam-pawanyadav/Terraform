# variables.tf — Variable Declarations
#
# All variables are declared here with:
#   - type: enforces what kind of value is accepted
#   - description: documents what the variable is for
#   - default: the fallback value if no override is provided

# -----------------------------------------------------------------------
# Simple string variable
# -----------------------------------------------------------------------
variable "instance_type" {
  description = "EC2 instance type (e.g. t2.micro, t2.large)"
  type        = string
  default     = "t2.micro"
}

# -----------------------------------------------------------------------
# VPN IP variable — used in security group CIDR blocks
# Change this once here instead of hunting through 20+ resource blocks
# -----------------------------------------------------------------------
variable "vpn_ip" {
  description = "VPN IP address in CIDR notation"
  type        = string
  default     = "116.50.30.20/32"
}

# -----------------------------------------------------------------------
# List variable — indexed access: var.az_list[0], var.az_list[1] ...
# -----------------------------------------------------------------------
variable "az_list" {
  description = "List of EC2 instance types"
  type        = list(string)
  default     = ["m5.large", "m5.xlarge", "t2.medium"]
}

# -----------------------------------------------------------------------
# Map variable — key-based access: var.instance_types["us-east-1"]
# -----------------------------------------------------------------------
variable "instance_types" {
  description = "EC2 instance type per AWS region"
  type        = map(string)
  default = {
    us-east-1  = "t2.micro"
    us-west-2  = "t2.nano"
    ap-south-1 = "t2.small"
  }
}
