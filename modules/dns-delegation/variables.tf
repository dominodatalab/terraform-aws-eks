variable "parent_zone_id" {
  description = "Route 53 hosted zone ID of the parent zone."
  type        = string
}

variable "delegation_name" {
  description = "FQDN of the subdomain being delegated, e.g. \"azure-east.acme.domino.tech\"."
  type        = string
}

variable "nameservers" {
  description = "NS values from the child zone (Azure DNS, GCP DNS, etc.). Azure returns these with a trailing dot; Route 53 accepts either form, so no normalization is needed."
  type        = list(string)
}

variable "ttl" {
  description = "TTL for the NS delegation record."
  type        = number
  default     = 300
}

variable "allow_overwrite" {
  description = "Allow overwriting an existing NS record in the parent zone (e.g. adopting a pre-existing delegation). Route 53 manages NS/SOA records specially, making import painful; default false keeps create-only behavior."
  type        = bool
  default     = false
}
