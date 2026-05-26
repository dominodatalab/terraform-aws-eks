# dns-delegation

Creates an NS delegation record in a Route 53 parent zone, pointing a subdomain to nameservers in a child zone hosted on another cloud provider (Azure DNS, GCP Cloud DNS, etc.). Designed for AKS-dataplane / EKS-control-plane topologies where DNS must bridge clouds.

## Usage

```hcl
module "dns_delegation" {
  source = "../../modules/dns-delegation"

  providers = {
    aws = aws.global
  }

  parent_zone_id  = "Z0123456789ABCDEFGHIJ"
  delegation_name = "azure-east.acme.domino.tech"
  nameservers     = [
    "ns1-01.azure-dns.com.",
    "ns2-01.azure-dns.net.",
    "ns3-01.azure-dns.org.",
    "ns4-01.azure-dns.info.",
  ]
  ttl = 300
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_delegation_name"></a> [delegation\_name](#input\_delegation\_name) | FQDN of the subdomain being delegated, e.g. "azure-east.acme.domino.tech". | `string` | n/a | yes |
| <a name="input_nameservers"></a> [nameservers](#input\_nameservers) | NS values from the child zone (Azure DNS, GCP DNS, etc.). | `list(string)` | n/a | yes |
| <a name="input_parent_zone_id"></a> [parent\_zone\_id](#input\_parent\_zone\_id) | Route 53 hosted zone ID of the parent zone. | `string` | n/a | yes |
| <a name="input_ttl"></a> [ttl](#input\_ttl) | TTL for the NS delegation record. | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_record_fqdn"></a> [record\_fqdn](#output\_record\_fqdn) | FQDN of the NS delegation record. |
| <a name="output_record_name"></a> [record\_name](#output\_record\_name) | Name of the NS delegation record. |
<!-- END_TF_DOCS -->
