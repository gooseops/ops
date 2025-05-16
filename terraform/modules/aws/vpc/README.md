# AWS Virtual Private Cloud
This is a terraform module for creating all things necessary for an AWS VPC

## Examples
Please see the `example` directory in each module version for ways the module can be used in a worlds directory

## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [aws](https://registry.terraform.io/providers/hashicorp/aws/latest)

## Resources
- `aws_vpc`: AWS Virtual Private Cloud for placing networking and compute resources
- `aws_subnet`: AWS Subnet for allocating networks withing the VPC
- `aws_route_table`: AWS Route Table for managing routes for the subnets
- `aws_route_table_association`: AWS RT Association for connecting the RT to the subnets
- `aws_route` (init): The route to the gateway for all traffic.  (default route)
- `aws_route` (custom): Any dynamically created routes that can be defined in the module definition

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
- 2.0.0: Added `aws_route` resource for dynamic and scalable route creation
