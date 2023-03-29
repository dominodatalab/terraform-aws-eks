
# Create additional EKS node_group.

### Provide full path for existing ssh key:  `ssh_pvt_key_path`
### Otherwise generate using:
```bash
ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f domino.pem
```
### Create an additional node_group.

```hcl
  additional_node_groups = {
    custom-group-0 = {
      instance_types = [
        "m5.2xlarge"
      ],
      min_per_az     = 0,
      max_per_az     = 10,
      desired_per_az = 0,
      availability_zone_ids = [
        "usw2-az1",
        "usw2-az2"
      ],
      labels = {
        "dominodatalab.com/node-pool" = "custom-group-0"
      },
      volume = {
        size = 100,
        type = "gp3"
      }
    }
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
