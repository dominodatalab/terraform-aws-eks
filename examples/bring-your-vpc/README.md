# Create EKS in existing VPC using existing subnets

### Provide full path for existing ssh key:  `ssh_pvt_key_path`
### Otherwise generate using:

```bash
ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f domino.pem
```
### The following skips Network/VPC assets and uses the provided instead.
```hcl
  network = {
    vpc = {
      id = "Existing vpc id"
      subnets = {
        private = "List of existing private subnets ids"
        public  = "List of existing public subnets ids"
        pod     = "List of existing subnets ids for pod networking"
      }
    }
  }
```

### A separate subnet is recomended for large scale deployments to mitigate IP address starvation. If you dont want to provide separate subnets for pod networking, set `network.use_pod_cidr: false` and ommit the `network.vpc.subnets.pod` value.

```hcl
  network = {
    vpc = {
      id = "Existing vpc id"
      subnets = {
        private = "List of existing private subnets ids"
        public  = "List of existing public subnets ids"
      }
    }
    use_pod_cidr = false
  }
```


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.2.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 3.4.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_domino_eks"></a> [domino\_eks](#module\_domino\_eks) | ./../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
