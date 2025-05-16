# AWS Route Table
This is a terraform module for creating all things necessary for an AWS Route Table

## Examples
Please see the `example` directory in each module version for ways the module can be used in a worlds directory

## Providers
See `providers.tf` of each release for minimum provider version this module supports.

- [aws](https://registry.terraform.io/providers/hashicorp/aws/latest)

## Resources
- `aws_route_table`: Manage a single Doppler secret in a config 
- `aws_route_table_association`: An association of the route table being created to the defined subnets
- `aws_route`: Defined networking routes to add to the route table being created

## Configuration
See `variables.tf` in each release for variable configuration, defaults, and descriptions about the available configurations for this module.

## Releases
- 1.0.0: Initial Release
