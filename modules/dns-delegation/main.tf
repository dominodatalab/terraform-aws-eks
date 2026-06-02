resource "aws_route53_record" "this" {
  zone_id         = var.parent_zone_id
  name            = var.delegation_name
  type            = "NS"
  ttl             = var.ttl
  records         = var.nameservers
  allow_overwrite = var.allow_overwrite

  lifecycle {
    precondition {
      condition     = length(var.nameservers) > 0
      error_message = "nameservers must be non-empty."
    }
  }
}
