# Leave as [] to skip provisioning load balancers/Global Accelerator entirely.
load_balancers = []

# Example:
# load_balancers = [
#   {
#     name     = "domino"
#     type     = "application"
#     internal = true
#     listeners = [
#       {
#         name        = "https"
#         port        = 443
#         protocol    = "HTTPS"
#         tg_protocol = "HTTP"
#         cert_arn    = "arn:aws:acm:us-west-2:111111111111:certificate/00000000-0000-0000-0000-000000000000"
#       }
#     ]
#   },
#   {
#     name     = "domino-connect"
#     type     = "network"
#     internal = true
#     listeners = [
#       {
#         name        = "connect"
#         port        = 8888
#         protocol    = "TCP"
#         tg_protocol = "TCP"
#       }
#     ]
#   }
# ]

waf = {
  enabled = false
  rate_limit = {
    enabled = false
    limit   = 1000
    action  = "count"
  }
  block_forwarder_header = {
    enabled = false
  }
}

access_logs              = { enabled = false }
connection_logs          = { enabled = false }
flow_logs                = { enabled = false }
route53_hosted_zone_name = null
hosted_zone_private      = false
privatelink              = { enabled = false }
use_fips_endpoint        = false
