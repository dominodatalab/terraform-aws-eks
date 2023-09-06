module "privatelink" {
  count                    = var.privatelink.enabled ? 1 : 0
  source                   = "./submodules/privatelink"
  deploy_id                = var.deploy_id
  region                   = var.region
  vpc_endpoint_services    = var.privatelink.vpc_endpoint_services
  route53_hosted_zone_name = var.privatelink.route53_hosted_zone_name
  network_info             = var.network_info
  monitoring_bucket        = var.privatelink.monitoring_bucket
  namespace                = var.privatelink.namespace
  oidc_provider_id         = aws_iam_openid_connect_provider.oidc_provider.id
}