# subnets-cidr

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Map of availability zone: names - >  ids where the subnets will be created | `map(string)` | <pre>{<br>  "us-west-2a": "usw2-az1",<br>  "us-west-2b": "usw2-az2",<br>  "us-west-2c": "usw2-az3"<br>}</pre> | no |
| <a name="input_base_cidr_block"></a> [base\_cidr\_block](#input\_base\_cidr\_block) | CIDR block to serve the main private and public subnets | `string` | `"10.0.0.0/16"` | no |
| <a name="input_private_cidr_network_bits"></a> [private\_cidr\_network\_bits](#input\_private\_cidr\_network\_bits) | Number of network bits to allocate to the public subnet. i.e /19 -> 8,190 IPs | `number` | `19` | no |
| <a name="input_public_cidr_network_bits"></a> [public\_cidr\_network\_bits](#input\_public\_cidr\_network\_bits) | Number of network bits to allocate to the public subnet. i.e /27 -> 30 IPs | `number` | `27` | no |
| <a name="input_subnet_name_prefix"></a> [subnet\_name\_prefix](#input\_subnet\_name\_prefix) | String to serve as a prefix/identifier when naming the subnets | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | Map containing the CIDR information for the private subnets |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | Map containing the CIDR information for the public subnets |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
