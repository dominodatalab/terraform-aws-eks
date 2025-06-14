module "load_balancers" {
  count = length(var.load_balancers) > 0 ? 1 : 0

  source         = "./submodules/load-balancers"
  deploy_id      = var.deploy_id
  load_balancers = var.load_balancers
  waf            = var.waf

  access_logs = {
    enabled   = var.monitoring_bucket != null
    s3_bucket = var.monitoring_bucket
  }
  connection_logs = {
    enabled   = var.monitoring_bucket != null
    s3_bucket = var.monitoring_bucket
  }
  flow_logs = {
    enabled   = var.monitoring_bucket != null
    s3_bucket = var.monitoring_bucket
  }
  fqdn                        = var.fqdn
  hosted_zone_name            = var.hosted_zone_name
  network_info                = var.network_info
  eks_nodes_security_group_id = aws_security_group.eks_nodes.id
}