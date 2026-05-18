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
