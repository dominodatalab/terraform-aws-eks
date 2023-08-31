module "privatelink" {
  source                   = "./submodules/privatelink"
  deploy_id                = var.deploy_id
  region                   = var.region
  vpc_endpoint_services    = var.vpc_endpoint_services
  route53_hosted_zone_name = var.route53_hosted_zone_name
  network_info             = var.network_info
  monitoring_bucket        = var.monitoring_bucket
  oidc_provider_id         = aws_iam_openid_connect_provider.oidc_provider.id
}