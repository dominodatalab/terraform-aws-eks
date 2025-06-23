module "privatelink" {
  count       = var.privatelink.enabled && length(var.load_balancers) > 0 ? 1 : 0
  source      = "./submodules/privatelink"
  deploy_id   = var.deploy_id
  privatelink = var.privatelink
  lb_arns     = try(module.load_balancers[0].info.lb_arns, {})
}
