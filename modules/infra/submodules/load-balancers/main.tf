locals {
  albs = {
    for lb in var.load_balancers : lb.name => lb
    if lower(lb.type) == "alb"
  }

  nlbs = {
    for lb in var.load_balancers : lb.name => lb
    if lower(lb.type) == "nlb"
  }
}