# 🧠 Core Concepts Deep Dive

Supplementary reference for the most commonly misunderstood Terraform concepts.

---

## State File — What Is It Exactly?

The Terraform state file (`terraform.tfstate`) is a JSON file that maps your `.tf` resource declarations to real-world infrastructure IDs.

**Example state entry for an EC2 instance:**
```json
{
  "resources": [
    {
      "type": "aws_instance",
      "name": "my_ec2",
      "instances": [
        {
          "attributes": {
            "id": "i-0ede7e2ee93a01bb7",
            "ami": "ami-05b622b5fa0269787",
            "instance_type": "t2.micro",
            "public_ip": "44.242.125.237"
          }
        }
      ]
    }
  ]
}
```

Terraform uses this to:
1. Know which real AWS resource corresponds to each block in your `.tf` file
2. Calculate what needs to change when you run `terraform plan`
3. Release resources cleanly during `terraform destroy`

---

## Why You Must Never Manually Edit the State File

The state file is authoritative. A manual edit that introduces invalid JSON, changes an ID incorrectly, or removes a resource will cause Terraform to behave unpredictably — potentially destroying infrastructure it thinks no longer exists, or failing to manage resources it can't find.

Always use `terraform state` sub-commands:
```bash
terraform state mv   # Rename
terraform state rm   # Remove without destroying
terraform state list # Inspect
```

---

## Desired State vs Current State vs State File

These three things are distinct and it's important to keep them separate in your mind:

| Concept | What it is |
|---|---|
| **Desired State** | What your `.tf` files declare the infrastructure *should* look like |
| **State File** | Terraform's *last known* snapshot of what was created |
| **Current State** | The *actual live* state of infrastructure in AWS/GCP/etc. right now |

### Key insight

When you run `terraform plan`, Terraform:
1. Reads your `.tf` files (desired state)
2. Calls the provider API to fetch the current real-world state
3. Compares current state against desired state
4. Outputs any differences as a plan
5. **Also** updates the state file to reflect any drift it discovered

If you manually change something in AWS that is **not declared** in your `.tf` files, Terraform will update the state file to reflect it but will **not** plan to revert it — because it was never part of desired state.

---

## Resource Type vs Local Resource Name

```hcl
resource "aws_instance" "my_ec2" {
#         ^^^^^^^^^^^^ ^^^^^^
#         Resource     Local
#         Type         Name
```

- **Resource Type** (`aws_instance`) — fixed, defined by Terraform/provider, cannot be changed
- **Local Resource Name** (`my_ec2`) — chosen by you, used only within your Terraform code as a reference label. It is NOT the name that appears in AWS.

The combination of both makes a unique address: `aws_instance.my_ec2`

---

## Terraform Init — What Actually Happens

```
terraform init
```

1. Reads all `.tf` files to discover required providers and modules
2. Downloads provider plugins (e.g. `hashicorp/aws`) into `.terraform/providers/`
3. Downloads any module sources into `.terraform/modules/`
4. Sets up the configured backend (local or remote)
5. Generates or updates `terraform.lock.hcl`

You must re-run `terraform init` whenever you:
- Add a new provider
- Add or update a module source
- Change the backend configuration

---

## Dependency Graph — How Terraform Orders Operations

Terraform builds an internal dependency graph from your configuration. Resources that reference other resources' attributes are automatically sequenced correctly.

```hcl
resource "aws_instance" "my_ec2" { ... }
resource "aws_eip" "lb" { ... }

resource "aws_eip_association" "assoc" {
  instance_id   = aws_instance.my_ec2.id   # ← depends on aws_instance
  allocation_id = aws_eip.lb.id             # ← depends on aws_eip
}
```

Terraform knows: create `aws_instance` and `aws_eip` first (in parallel if possible), then create `aws_eip_association`.

---

## Provider Authentication — Best Practices by Environment

| Environment | Recommended Method |
|---|---|
| Local development | Environment variables (`AWS_ACCESS_KEY_ID`, etc.) |
| CI/CD pipeline | Environment variables injected by the pipeline secrets manager |
| EC2 / ECS / Lambda | IAM instance roles / task roles — no keys needed |
| Production (human) | IAM Identity Center (SSO) |

**Never** commit access keys to git. **Never** hardcode them in `.tf` files beyond initial experimentation.

---

## The `self` Reference in Provisioners

Inside a `provisioner` or `connection` block, `self` refers to the parent resource:

```hcl
resource "aws_instance" "my_ec2" {
  # ...
  connection {
    host = self.public_ip   # = aws_instance.my_ec2.public_ip
  }
}
```

This avoids circular references that would occur if you tried to reference the resource by name from within itself.

---

## Module vs count — When to Use Which

| Use case | Tool |
|---|---|
| Create 5 identical EC2s in one project | `count` |
| Reuse an EC2 pattern across dev, staging, prod projects | `module` |
| Create 3 IAM users with different names in one config | `count` + list variable |
| Share a VPC setup between two teams' projects | `module` |

---

## Workspace vs Separate Directories

Both let you manage separate environments, but with important trade-offs:

| | Workspaces | Separate directories |
|---|---|---|
| State isolation | Yes (separate state per workspace) | Yes (separate directory = separate state) |
| Code sharing | Same codebase | Can diverge |
| Variable overrides | Per-workspace `.tfvars` files | Separate `.tfvars` per directory |
| Recommended for | Small teams, simple environment differences | Large teams, significantly different environments |

---

## Remote State — DynamoDB Locking Explained

When two engineers run `terraform apply` simultaneously against the same S3 state file:

1. Engineer A's apply locks the state by writing a lock record to DynamoDB
2. Engineer B's apply tries to acquire the lock — DynamoDB returns a conflict
3. Engineer B sees: `Error: Error acquiring the state lock`
4. Engineer A's apply completes and releases the lock
5. Engineer B can now re-run their apply

Without DynamoDB locking, both applies would read the same state file, make decisions based on it, and write conflicting results back — corrupting the state.

**DynamoDB table requirements:**
- Table name: anything (configure in backend block)
- Primary key: `LockID` (type: String)
- No sort key needed
