## Terraform
Terraform is an infrastructure as code tool that lets you build, change, and version infrastructure safely and efficiently. This includes low-level components like compute instances, storage, and networking; and high-level components like DNS entries and SaaS features. See official [docs](developer.hashicorp.com/terraform?product_intent=terraform) for more information regarding Terraform.

### Purpose
This directory will be the root of all things Terraform - modules, worlds, etc.

### Directory Structure
- `modules` will be at the root of this directory and contain all custom terraform modules
- `worlds` will be at the root of this directory and contain worlds configurations for different terraform declarative states and use the modules available in this repository