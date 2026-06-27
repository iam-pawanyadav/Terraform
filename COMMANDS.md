# ⚡ Terraform CLI Commands — Quick Reference

All commands you'll ever need, grouped by category.

---

## Core Workflow

| Command | Description |
|---|---|
| `terraform init` | Initialise directory, download provider plugins, set up backend |
| `terraform plan` | Preview infrastructure changes (dry run) |
| `terraform apply` | Apply changes to real infrastructure |
| `terraform destroy` | Destroy all resources managed in this directory |

---

## Targeted Operations

```bash
# Plan/apply/destroy only a specific resource
terraform plan    -target=aws_instance.my_ec2
terraform apply   -target=aws_instance.my_ec2
terraform destroy -target=aws_instance.my_ec2

# Syntax: resource_type.local_resource_name
```

---

## Plan to File & Apply from File

```bash
# Save plan output to a file
terraform plan -out=myplan.tfplan

# Apply exactly that plan (no prompt)
terraform apply myplan.tfplan
```

---

## Variables at Runtime

```bash
# Override a variable on the command line
terraform plan -var="instance_type=t2.small"
terraform apply -var="instance_type=t2.small"

# Use a specific .tfvars file
terraform apply -var-file="prod.tfvars"
terraform apply -var-file="staging.tfvars"
```

---

## Providers & Initialisation

```bash
# Initialise and install providers
terraform init

# Upgrade providers to newest allowed version (ignores lock file)
terraform init -upgrade
```

---

## State Management

```bash
terraform state list                          # List all tracked resources
terraform state show aws_instance.my_ec2     # Show attributes of one resource
terraform state mv aws_instance.old aws_instance.new   # Rename in state
terraform state rm aws_instance.my_ec2       # Remove from state (don't destroy)
terraform state pull                          # Print remote state to stdout
terraform state push terraform.tfstate        # Push local state to remote
```

---

## Import Existing Resources

```bash
# Bring a manually-created resource into Terraform state
terraform import aws_instance.my_ec2 <AWS_INSTANCE_ID>
```

---

## Taint / Replace (Force Destroy & Recreate)

```bash
# Modern (v0.15.2+) — preferred
terraform apply -replace aws_instance.my_ec2

# Legacy (deprecated)
terraform taint   aws_instance.my_ec2
terraform untaint aws_instance.my_ec2
```

---

## Validation & Formatting

```bash
terraform validate          # Check config syntax
terraform fmt               # Format all .tf files in directory
terraform fmt my_ec2.tf     # Format a specific file
terraform fmt -check        # Check formatting without writing (useful in CI)
```

---

## Output Values

```bash
terraform output                    # Show all outputs
terraform output eip_public_ip      # Show one specific output
```

---

## Graph Visualisation

```bash
terraform graph > graph.dot
dot -Tpng graph.dot -o graph.png    # Requires graphviz: sudo apt install graphviz
```

---

## Terraform Console (Interactive)

```bash
terraform console
> max(5, 12, 9)      # Test functions interactively
> var.instance_type  # Inspect variable values
> exit
```

---

## Workspaces

```bash
terraform workspace new staging       # Create new workspace
terraform workspace list              # List all workspaces
terraform workspace select staging    # Switch to a workspace
terraform workspace show              # Print current workspace name
terraform workspace delete staging    # Delete a workspace
```

---

## Skip State Refresh

```bash
# Plan without refreshing state from provider APIs (faster for large configs)
terraform plan -refresh=false
# Resources in the plan will be prefixed with ~ (updated in place)
```

---

## Debugging

```bash
# Enable logging
export TF_LOG=TRACE    # TRACE > DEBUG > INFO > WARN > ERROR
export TF_LOG=DEBUG
export TF_LOG=INFO

# Send logs to a file
export TF_LOG_PATH=./terraform.log

# Disable logging
export TF_LOG=
```

---

## Environment Variable Authentication (AWS)

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

---

## Environment Variables for Terraform Variables

```bash
# Prefix TF_VAR_ + variable name
export TF_VAR_instance_type="t2.nano"
export TF_VAR_region="us-east-1"
```

---

## Provider Version Constraints Syntax

| Constraint | Meaning |
|---|---|
| `>= 1.0` | 1.0 or higher |
| `<= 1.0` | 1.0 or lower |
| `~> 2.0` | Any 2.x version |
| `>= 2.10, <= 2.30` | Between 2.10 and 2.30 |
| `!= 1.5.0` | Anything except 1.5.0 |
