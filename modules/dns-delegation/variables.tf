variable "parent_zone_id" {
  description = "Route 53 hosted zone ID of the parent zone."
  type        = string
}

variable "delegation_name" {
  description = "FQDN of the subdomain being delegated, e.g. \"azure-east.acme.domino.tech\"."
  type        = string
}

variable "nameservers" {
  description = "NS values from the child zone (Azure DNS, GCP DNS, etc.)."
  type        = list(string)
}

variable "ttl" {
  description = "TTL for the NS delegation record."
  type        = number
  default     = 300
}
