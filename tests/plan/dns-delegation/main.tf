module "dns_delegation" {
  source = "../../../modules/dns-delegation"

  parent_zone_id  = "Z0123456789ABCDEFGHIJ"
  delegation_name = "azure-east.example.domino.tech"
  nameservers = [
    "ns1-01.azure-dns.com.",
    "ns2-01.azure-dns.net.",
    "ns3-01.azure-dns.org.",
    "ns4-01.azure-dns.info.",
  ]
  ttl = 300
}
