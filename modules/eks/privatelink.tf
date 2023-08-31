module "privatelink" {
  source                   = "./submodules/privatelink"
  deploy_id                = var.deploy_id
  region                   = var.region
  vpc_endpoint_services    = var.vpc_endpoint_services
  route53_hosted_zone_name = var.route53_hosted_zone_name
  network_info             = var.network_info
  oidc_provider_id         = var.oidc_provider_id
  monitoring_bucket        = var.monitoring_bucket
}