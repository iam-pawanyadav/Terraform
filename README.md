# 🌍 Ultimate Terraform Guide — Beginner to Expert

A structured, example-driven Terraform reference covering every core concept you need — from your first EC2 instance to production-ready modules, remote backends, and collaboration patterns. Also doubles as solid exam notes for the **HashiCorp Terraform Associate Certification**.

> **Focus:** AWS (as the primary provider), but the concepts apply universally across GCP, Azure, GitHub, and any other Terraform provider.

---

## 📁 Repository Structure

```
terraform-guide/
│
├── README.md                          ← You are here — full concept reference
├── COMMANDS.md                        ← Quick-reference cheat sheet for all CLI commands
├── CONCEPTS.md                        ← Deep-dive: State, Desired State, Providers, Versioning
│
├── examples/
│   ├── 01-simple-ec2/                 ← Your first EC2 instance
│   ├── 02-github-repo/                ← Using a non-AWS provider
│   ├── 03-variables/                  ← Variables, tfvars, maps, lists
│   ├── 04-count-loops/                ← count, count.index, IAM users
│   ├── 05-dynamic-blocks/             ← Dynamic security group ingress rules
│   ├── 06-provisioners/               ← local-exec and remote-exec
│   ├── 07-modules/                    ← Calling reusable modules
│   └── 08-remote-backend/             ← S3 remote state + DynamoDB locking
│
├── modules/
│   └── ec2/                           ← Reusable EC2 module with variable inputs
│
└── .gitignore                         ← Terraform-safe gitignore
```

---

## 📚 Table of Contents

1. [What is Terraform?](#1-what-is-terraform)
2. [Infrastructure as Code — Tool Landscape](#2-infrastructure-as-code--tool-landscape)
3. [Providers](#3-providers)
4. [Resources](#4-resources)
5. [Core Workflow — init, plan, apply, destroy](#5-core-workflow--init-plan-apply-destroy)
6. [Terraform State](#6-terraform-state)
7. [Desired State vs Current State](#7-desired-state-vs-current-state)
8. [Provider Versioning & Lock File](#8-provider-versioning--lock-file)
9. [Attributes & Output Values](#9-attributes--output-values)
10. [Cross-Resource Attribute References](#10-cross-resource-attribute-references)
11. [Variables](#11-variables)
12. [Variable Data Types](#12-variable-data-types)
13. [Maps and Lists](#13-maps-and-lists)
14. [Conditional Expressions](#14-conditional-expressions)
15. [Local Values](#15-local-values)
16. [Built-in Functions](#16-built-in-functions)
17. [Data Sources](#17-data-sources)
18. [count & count.index](#18-count--countindex)
19. [Dynamic Blocks](#19-dynamic-blocks)
20. [Splat Expressions](#20-splat-expressions)
21. [Terraform Taint / Replace](#21-terraform-taint--replace)
22. [Debugging & Formatting](#22-debugging--formatting)
23. [Terraform Validate](#23-terraform-validate)
24. [Load Order & File Structure](#24-load-order--file-structure)
25. [Handling Large Infrastructure](#25-handling-large-infrastructure)
26. [Provisioners](#26-provisioners)
27. [Modules & the DRY Principle](#27-modules--the-dry-principle)
28. [Terraform Registry Modules](#28-terraform-registry-modules)
29. [Workspaces](#29-workspaces)
30. [Remote Backend & State Locking](#30-remote-backend--state-locking)
31. [Collaboration & .gitignore](#31-collaboration--gitignore)
32. [Terraform Import](#32-terraform-import)
33. [Terraform Cloud](#33-terraform-cloud)

---

## 1. What is Terraform?

Terraform is an **infrastructure orchestration** tool built by HashiCorp. You write declarative configuration files (`.tf`) that describe the infrastructure you want, and Terraform figures out how to create, update, or destroy resources to match that description.

**Key benefits:**
- Supports multiple providers — AWS, GCP, Azure, GitHub, and hundreds more
- Simple, readable HCL (HashiCorp Configuration Language) syntax
- Fast learning curve
- Easy to integrate with configuration management tools like Ansible
- Free and open-source (core CLI)

---

## 2. Infrastructure as Code — Tool Landscape

Not all IaC tools do the same job. Understanding the distinction matters:

| Category | Tools | Purpose |
|---|---|---|
| **Infrastructure Orchestration** | Terraform, CloudFormation, Heat | Provision servers and infrastructure |
| **Configuration Management** | Ansible, Chef, Puppet, SaltStack | Install and manage software on existing servers |

> 💡 You can use both together: Terraform creates an EC2 instance, then calls Ansible to install and configure software on it.

---

## 3. Providers

A **provider** is the platform Terraform will provision infrastructure on (AWS, GCP, Azure, GitHub, etc.). You must declare the provider in your `.tf` file, and Terraform downloads its plugin during `terraform init`.

### Best Practice Provider Syntax (Terraform v0.13+)

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = "us-west-2"
  access_key = "YOUR_ACCESS_KEY"   # Not recommended for production
  secret_key = "YOUR_SECRET_KEY"   # Use environment variables or IAM roles instead
}
```

> ⚠️ Hardcoding credentials in `.tf` files is only acceptable for local learning. In production, use environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) or IAM instance roles.

> 💡 Grab the exact provider block from [registry.terraform.io](https://registry.terraform.io) — click **"Use Provider"** on any provider page.

**Adding a new provider always requires re-running `terraform init`** to download its plugin.

---

## 4. Resources

Resources are references to individual services a provider offers.

**Syntax:**
```hcl
resource "<RESOURCE_TYPE>" "<LOCAL_NAME>" {
  # arguments
}
```

- `RESOURCE_TYPE` — fixed Terraform identifier (e.g. `aws_instance`, `github_repository`)
- `LOCAL_NAME` — your custom name, used only within Terraform code as a reference

**Example:**
```hcl
resource "aws_instance" "my_ec2" {
  ami           = "ami-05b622b5fa0269787"
  instance_type = "t2.micro"
}
```

Browse all resource types for any provider at the [Terraform Registry](https://registry.terraform.io).

---

## 5. Core Workflow — init, plan, apply, destroy

```
terraform init     → Download provider plugins, set up backend
terraform plan     → Preview what changes will be made (also validates syntax)
terraform apply    → Create/update infrastructure (prompts for confirmation)
terraform destroy  → Destroy all resources in the current folder
```

### Targeted operations

```bash
# Destroy only one specific resource
terraform destroy -target aws_instance.my_ec2

# Syntax: resource_type.local_resource_name
```

### Save a plan to file (recommended for CI/CD)

```bash
terraform plan -out=myplan.tfplan
terraform apply myplan.tfplan
```

This guarantees only the exact changes previewed in the plan are applied.

---

## 6. Terraform State

Terraform stores the **real-world state** of every resource it manages in a **state file** (`terraform.tfstate`).

**How it works:**
- `terraform init` creates the state file in your working directory
- `terraform apply` adds newly created resources to the state file
- `terraform destroy` removes destroyed resources from the state file
- On every `terraform plan`, Terraform compares your `.tf` config against the state file and the actual live infrastructure

> 🚫 **Never manually edit the state file.** Use `terraform state` sub-commands instead.

### `terraform state` sub-commands

| Sub-command | What it does |
|---|---|
| `terraform state list` | List all resources tracked in state |
| `terraform state show <resource>` | Show attributes of a single resource |
| `terraform state mv <src> <dest>` | Rename/move a resource in state |
| `terraform state rm <resource>` | Remove a resource from state (without destroying it) |
| `terraform state pull` | Download and print remote state |
| `terraform state push` | Upload a local state file to remote state |

---

## 7. Desired State vs Current State

| Term | Meaning |
|---|---|
| **Desired State** | What your `.tf` files say the infrastructure should look like |
| **Current State** | The actual live state of your deployed infrastructure |

- `terraform plan` shows you what changes are needed to bring current state **in line with** desired state
- If something is **not specified** in your `.tf` file, it is **not part of desired state** — Terraform won't manage it

**Example:** If you don't specify a security group for an EC2 instance, Terraform places it in the default group. If you later manually change it in the AWS console, `terraform plan` will **not** try to revert it — because the security group was never part of your desired state. Terraform will simply update the state file to reflect the new reality.

---

## 8. Provider Versioning & Lock File

### Version constraints

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"   # Any 3.x version
    }
  }
}
```

**Version constraint syntax:**

| Constraint | Meaning |
|---|---|
| `>= 1.0` | Greater than or equal to 1.0 |
| `<= 1.0` | Less than or equal to 1.0 |
| `~> 2.0` | Any version in the 2.X range |
| `>= 2.10, <= 2.30` | Between 2.10 and 2.30 inclusive |

### Dependency lock file

The `terraform.lock.hcl` file locks your project to specific provider versions. Once recorded, `terraform init` always re-selects that version.

To upgrade to a newer version:
```bash
terraform init -upgrade
```

---

## 9. Attributes & Output Values

Terraform can **output attributes** of created resources — useful for displaying IPs, domain names, ARNs, and more. Output values can also feed into other resources.

```hcl
# Create an Elastic IP
resource "aws_eip" "lb" {
  vpc = true
}

# Output its public IP
output "eip_public_ip" {
  value = aws_eip.lb.public_ip
}

# Create an S3 bucket
resource "aws_s3_bucket" "mys3" {
  bucket = "my-unique-bucket-name-xyz"
}

# Output its domain name
output "s3_domain" {
  value = aws_s3_bucket.mys3.bucket_domain_name
}
```

To retrieve output values after `apply`:
```bash
terraform output
terraform output eip_public_ip
```

---

## 10. Cross-Resource Attribute References

Output attributes of one resource can be used directly as inputs to another — this is how Terraform builds dependency graphs automatically.

```hcl
resource "aws_instance" "my_ec2" {
  ami           = "ami-05b622b5fa0269787"
  instance_type = "t2.micro"
}

resource "aws_eip" "lb" {
  vpc = true
}

# Attach the EIP to the EC2 — references attributes of both
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.my_ec2.id   # .id is an attribute of aws_instance
  allocation_id = aws_eip.lb.id             # .id is an attribute of aws_eip
}
```

Terraform automatically determines that `aws_eip_association` must be created **after** both the EC2 and EIP exist.

---

## 11. Variables

Variables centralise values so you only change them in one place.

### Define a variable

```hcl
# variables.tf
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
```

### Use a variable

```hcl
resource "aws_instance" "my_ec2" {
  ami           = "ami-05b622b5fa0269787"
  instance_type = var.instance_type
}
```

### Ways to assign/override variable values (in priority order)

| Method | How | Priority |
|---|---|---|
| Environment variable | `export TF_VAR_instance_type="t2.nano"` | **Highest** |
| `terraform.tfvars` file | `instance_type = "t2.large"` | High |
| Command-line flag | `terraform plan -var="instance_type=t2.small"` | Medium |
| Variable default | `default = "t2.micro"` in variables block | Lowest |

**`terraform.tfvars`** is the recommended production approach. You can also pass a named file:
```bash
terraform apply -var-file="prod.tfvars"
```

> ✅ **Best Practice:** Define defaults in `variables.tf`, put environment-specific overrides in `terraform.tfvars`.

---

## 12. Variable Data Types

```hcl
variable "my_string" {
  type    = string
  default = "hello"
}

variable "my_number" {
  type    = number
  default = 42
}

variable "my_bool" {
  type    = bool
  default = true
}

variable "my_list" {
  type    = list(string)
  default = ["us-west-1a", "us-west-1c"]
}

variable "my_map" {
  type = map(string)
  default = {
    name = "Mabel"
    age  = "52"
  }
}
```

> ✅ **Best Practice:** Always specify `type` for every variable.

---

## 13. Maps and Lists

### Accessing a map value by key

```hcl
variable "instance_types" {
  type = map(string)
  default = {
    us-east-1 = "t2.micro"
    us-west-2 = "t2.nano"
    ap-south-1 = "t2.small"
  }
}

resource "aws_instance" "my_ec2" {
  ami           = "ami-05b622b5fa0269787"
  instance_type = var.instance_types["us-east-1"]  # → "t2.micro"
}
```

### Accessing a list value by index

```hcl
variable "az_list" {
  type    = list(string)
  default = ["m5.large", "m5.xlarge", "t2.medium"]
}

resource "aws_instance" "my_ec2" {
  ami           = "ami-05b622b5fa0269787"
  instance_type = var.az_list[0]   # → "m5.large" (index starts at 0)
}
```

---

## 14. Conditional Expressions

```
condition ? value_if_true : value_if_false
```

**Use case — build dev or prod based on a flag:**

```hcl
variable "istest" {}   # Set in terraform.tfvars

resource "aws_instance" "dev" {
  ami           = "ami-05b622b5fa0269787"
  instance_type = "t2.micro"
  count         = var.istest == true ? 1 : 0   # Create only if istest = true
}

resource "aws_instance" "prod" {
  ami           = "ami-05b622b5fa0269787"
  instance_type = "t2.large"
  count         = var.istest == false ? 1 : 0  # Create only if istest = false
}
```

In `terraform.tfvars`:
```hcl
istest = true
```

> ⚠️ Terraform uses lowercase booleans: `true` and `false`, not `True` / `False`.

---

## 15. Local Values

Local values are named expressions you can reuse within a module. Unlike variables, they can hold **computed expressions**, not just static values.

```hcl
locals {
  common_tags = {
    owner   = "DevOps Team"
    service = "backend"
  }

  # Expression-based local — can reference variables
  name_prefix = var.name != "" ? var.name : var.default_name
}

resource "aws_instance" "my_ec2" {
  ami           = "ami-05b622b5fa0269787"
  instance_type = "t2.micro"
  tags          = local.common_tags   # Note: "local" (no S) when referencing
}

resource "aws_ebs_volume" "db_ebs" {
  availability_zone = "us-west-2a"
  size              = 8
  tags              = local.common_tags
}
```

> 💡 Define locals with the `locals` block (plural), reference them with `local.name` (singular).

---

## 16. Built-in Functions

Terraform includes many built-in functions. You cannot define your own.

**Syntax:**
```
function_name(argument1, argument2)
```

**Common examples:**

```hcl
max(5, 12, 9)          # → 12
min(13, 16, 9)         # → 9
length(["a","b","c"])  # → 3
upper("hello")         # → "HELLO"
file("./path/to/file") # → contents of the file as a string

# zipmap — combine two lists into a map
zipmap(["a","b","c"], [1, 2, 3])
# → { a = 1, b = 2, c = 3 }
```

**Test functions interactively:**
```bash
terraform console
> max(5, 12, 9)
12
```

Full function reference: [developer.hashicorp.com/terraform/language/functions](https://developer.hashicorp.com/terraform/language/functions)

### zipmap in practice

```hcl
resource "aws_iam_user" "lb" {
  name  = "iamuser.${count.index}"
  count = 3
  path  = "/system/"
}

output "combined" {
  value = zipmap(aws_iam_user.lb[*].name, aws_iam_user.lb[*].arn)
}
# Output: { "iamuser.0" = "arn:...", "iamuser.1" = "arn:...", ... }
```

---

## 17. Data Sources

Data sources let you **fetch information** from a provider and use it in your configuration — without hardcoding values that may change.

**Problem:** AMI IDs are region-specific. If you hardcode `ami-05b622b5fa0269787` (us-west-2), changing the provider region breaks your config.

**Solution — use a data source:**

```hcl
data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "my_ec2" {
  ami           = data.aws_ami.app_ami.id   # Always correct for the current region
  instance_type = "t2.micro"
}
```

Now you can change the `region` in your provider block and the correct AMI is fetched automatically.

---

## 18. count & count.index

The `count` parameter creates multiple instances of a resource from a single block.

### Basic count

```hcl
resource "aws_instance" "server" {
  ami           = "ami-05b622b5fa0269787"
  instance_type = "t2.micro"
  count         = 5   # Creates 5 EC2 instances: server[0] through server[4]
}
```

### count.index for unique names

```hcl
resource "aws_iam_user" "user" {
  name  = "user.${count.index}"   # → user.0, user.1, user.2 ...
  count = 5
  path  = "/system/"
}
```

### count.index + list variable for meaningful names

```hcl
variable "iam_users" {
  type    = list(string)
  default = ["dev-user", "staging-user", "prod-user"]
}

resource "aws_iam_user" "user" {
  name  = var.iam_users[count.index]   # → dev-user, staging-user, prod-user
  count = 3
  path  = "/system/"
}
```

---

## 19. Dynamic Blocks

Dynamic blocks eliminate repetition of nested blocks inside a resource. Supported in `resource`, `data`, `provider`, and `provisioner` blocks.

**Without dynamic blocks — verbose and hard to scale:**
```hcl
ingress {
  from_port   = 8200
  to_port     = 8200
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
ingress {
  from_port   = 8300
  to_port     = 8300
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
# ... repeat for every port
```

**With dynamic blocks:**

```hcl
variable "ingress_ports" {
  type        = list(number)
  description = "List of ingress ports"
  default     = [8200, 8201, 8300, 9200, 9500]
}

resource "aws_security_group" "dynamic_sg" {
  name        = "dynamic-sg"
  description = "Dynamic ingress rules"

  dynamic "ingress" {
    for_each = var.ingress_ports
    iterator = port                    # Optional: rename the iterator (default = block label)
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

### Dynamic blocks with multiple values (list of maps)

```hcl
variable "ingress_rules" {
  type = list(object({
    port = number
    cidr = string
  }))
  default = [
    { port = 8200, cidr = "0.0.0.0/0" },
    { port = 8201, cidr = "255.255.0.0/16" }
  ]
}

dynamic "ingress" {
  for_each = var.ingress_rules
  content {
    from_port   = ingress.value["port"]
    to_port     = ingress.value["port"]
    protocol    = "tcp"
    cidr_blocks = [ingress.value["cidr"]]
  }
}
```

---

## 20. Splat Expressions

Splat expressions (`[*]`) collect an attribute from **all** instances of a resource created by a `count` block.

```hcl
resource "aws_iam_user" "lb" {
  name  = "iamuser.${count.index}"
  count = 3
  path  = "/system/"
}

# Instead of:
# value = aws_iam_user.lb[0].arn
# value = aws_iam_user.lb[1].arn
# value = aws_iam_user.lb[2].arn

# Use splat:
output "all_arns" {
  value = aws_iam_user.lb[*].arn
}
```

---

## 21. Terraform Taint / Replace

When a resource's actual state diverges from what Terraform expects (e.g. after heavy manual changes), you can force it to be **destroyed and recreated** on the next apply.

**Modern approach (Terraform v0.15.2+):**
```bash
terraform apply -replace aws_instance.my_ec2
```

**Legacy command (deprecated):**
```bash
terraform taint aws_instance.my_ec2   # Marks as tainted in state file
terraform apply                        # Destroys and recreates on next apply
```

---

## 22. Debugging & Formatting

### Debugging

Set the `TF_LOG` environment variable to enable verbose logs:

```bash
export TF_LOG=TRACE    # Most verbose: TRACE > DEBUG > INFO > WARN > ERROR
export TF_LOG=DEBUG
export TF_LOG=INFO

# Write logs to a file instead of terminal
export TF_LOG_PATH=/path/to/terraform.log

# Disable logging
export TF_LOG=
```

### Formatting

Auto-format all `.tf` files in the current directory to canonical style:

```bash
terraform fmt            # Format all files in directory
terraform fmt my_ec2.tf  # Format a specific file
```

### Terraform Graph

Generate a visual dependency graph:

```bash
terraform graph > graph.dot
# Install graphviz, then:
dot -Tpng graph.dot -o graph.png
```

---

## 23. Terraform Validate

Check that configuration files are syntactically valid without running a plan:

```bash
terraform validate
```

Catches: unsupported arguments, undeclared variables, type mismatches, and more.

> 💡 `terraform plan` also runs validation internally before generating a plan.

---

## 24. Load Order & File Structure

- Terraform loads all `.tf` and `.tf.json` files in a directory **alphabetically**
- All files in the same directory are merged into one configuration

### Recommended production file structure

```
project/
├── providers.tf      ← provider and terraform blocks
├── variables.tf      ← all variable declarations
├── terraform.tfvars  ← variable value overrides (gitignored)
├── main.tf           ← primary resources (or split by resource type)
├── ec2.tf            ← EC2 resources
├── iam.tf            ← IAM resources
├── outputs.tf        ← all output blocks
└── locals.tf         ← local value definitions
```

---

## 25. Handling Large Infrastructure

Large configs hit **provider API rate limits** because `terraform plan` must refresh the state of every resource.

### Strategy 1: Split configs into smaller, independent directories

Each directory can be applied independently:
```bash
cd infrastructure/ec2 && terraform plan    # Only refreshes EC2 state
cd infrastructure/networking && terraform plan
```

### Strategy 2: Target a specific resource type

```bash
terraform plan -target=aws_instance.my_ec2
```

### Strategy 3: Skip state refresh

```bash
terraform plan -refresh=false
```

> ⚠️ Resources updated without refresh are marked with `~` (tilde) in the plan — meaning "updated in place, not refreshed."

---

## 26. Provisioners

Provisioners execute scripts **as part of resource creation or destruction**. There are two types:

### local-exec — run commands on your local machine

```hcl
resource "aws_instance" "my_ec2" {
  ami           = "ami-05b622b5fa0269787"
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "echo ${aws_instance.my_ec2.private_ip} >> private_ips.txt"
  }
}
```

> 💡 A powerful use of `local-exec` is triggering Ansible playbooks after infrastructure is created.

### remote-exec — run commands on the remote server

```hcl
resource "aws_instance" "my_ec2" {
  ami           = "ami-05b622b5fa0269787"
  instance_type = "t2.micro"
  key_name      = "TF-keys"

  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install -y nginx1.12",
      "sudo systemctl start nginx"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("./TF-keys.pem")
    host        = self.public_ip
  }
}
```

### Creation-time vs Destroy-time

```hcl
# Creation-time (default)
provisioner "remote-exec" {
  inline = ["sudo apt install nano"]
}

# Destroy-time
provisioner "remote-exec" {
  when   = destroy
  inline = ["sudo apt remove nano"]
}
```

### On failure behaviour

```hcl
provisioner "remote-exec" {
  on_failure = continue   # Don't taint resource if this fails
  inline     = ["some command"]
}
```

Default is `on_failure = fail` which marks the resource as tainted.

---

## 27. Modules & the DRY Principle

**DRY = Don't Repeat Yourself.**

Modules let you define a resource configuration once in a central location and reuse it across multiple projects.

### Call a local module

```hcl
module "web_server" {
  source           = "../../modules/ec2"
  type_of_instance = "t2.large"   # Override the module's variable
}
```

### Call a module from GitHub

```hcl
module "web_server" {
  source           = "git::https://github.com/username/mymodule.git"
  type_of_instance = "t2.large"
}

# Pull a specific branch
module "web_server" {
  source           = "git::https://github.com/username/mymodule.git?ref=branch1"
  type_of_instance = "t2.large"
}
```

> 💡 After adding a module reference, always run `terraform init` to install it.

**count vs modules:**
- `count` — avoids repeating yourself *within* one config file
- `modules` — avoids repeating yourself *across* different projects/environments

---

## 28. Terraform Registry Modules

The [Terraform Registry](https://registry.terraform.io/browse/modules) has a library of pre-built modules:

- **Community modules** — written and maintained by the community
- **Verified modules** — maintained by third-party providers (AWS, Azure, GCP, etc.)

```hcl
# Example: Using the official AWS VPC module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

---

## 29. Workspaces

Workspaces let you maintain **multiple isolated state files** within the same configuration, each with different variable values.

```bash
terraform workspace new staging
terraform workspace new production
terraform workspace list
terraform workspace select staging
terraform workspace show     # Print current workspace name
```

**Use case — different instance sizes per environment:**

```hcl
variable "instance_type" {
  default = "t2.micro"
}
```

`terraform.tfvars` for staging workspace → `instance_type = "t2.micro"`
`terraform.tfvars` for production workspace → `instance_type = "t2.large"`

Each workspace maintains a completely isolated state file.

---

## 30. Remote Backend & State Locking

### Why remote backend?

- Share one state file across your entire team
- State file is **locked** during `terraform apply` — prevents two simultaneous applies from corrupting state
- Keeps sensitive data out of your local filesystem and git history

### S3 Remote Backend (AWS)

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "path/to/mykey.tfstate"
    region = "eu-west-1"
  }
}
```

### DynamoDB State Locking

Add a DynamoDB table to prevent concurrent applies:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "path/to/mykey.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-lock"   # Table must exist with LockID as primary key
  }
}
```

> 🏢 Nearly all businesses using Terraform in production use remote backend for state files.

---

## 31. Collaboration & .gitignore

### Never commit these files:

```gitignore
# .gitignore

# Local .terraform directory (recreated by terraform init)
.terraform/

# tfvars files often contain sensitive values
terraform.tfvars
*.tfvars

# State files contain plaintext secrets
terraform.tfstate
terraform.tfstate.backup
*.tfstate
*.tfstate.*

# Crash logs
crash.log
crash.*.log

# Override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Saved plan files
*.tfplan
```

---

## 32. Terraform Import

Bring an **existing manually-created resource** under Terraform management:

1. Write the Terraform resource block for it in your `.tf` file
2. Run the import command to link it to the existing resource

```bash
terraform import aws_instance.my_ec2 <INSTANCE_ID_FROM_AWS>
```

> ⚠️ `terraform import` only updates the **state file**. It does not generate the `.tf` code — you must write that yourself first.

---

## 33. Terraform Cloud

Terraform Cloud is HashiCorp's managed service for running Terraform at scale:

- **Remote plan and apply** — consistent, auditable execution environment
- **Access controls** — team-based permissions
- **Private module registry** — share modules within your organisation
- **Policy controls** — enforce governance rules (Sentinel)
- **Remote state management** — no need to manage your own S3 backend

Get started at [app.terraform.io](https://app.terraform.io)

---

## 🔗 Further Resources

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terraform Registry](https://registry.terraform.io)
- [HashiCorp Terraform Associate Exam](https://www.hashicorp.com/certifications/terraform-associate)
- [Zeal Vora's Terraform Course on Udemy](https://www.udemy.com/user/zeal-vora/) *(highly recommended)*

---

*This guide was compiled from hands-on Terraform practice and is structured to cover all topics in the HashiCorp Terraform Associate certification.*
