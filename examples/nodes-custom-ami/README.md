# Specify AMI for the EKS nodes.

### Provide full path for existing ssh key:  `ssh_pvt_key_path`
### Otherwise generate using:

```bash
ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f domino.pem
```

### You can provide the ami id for any or all of the node_groups, Note that the `gpu` node_group needs a GPU specific AMI. By default EKS will determine the latest ami.

```hcl
data "aws_ami" "eks_node" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.25-*"]
  }

  filter {
    name   = "owner-id"
    values = ["602401143452"] # Amazon EKS AMI account ID
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# GPU
data "aws_ami" "eks_gpu_node" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-gpu-node-1.25-*"]
  }

  filter {
    name   = "owner-id"
    values = ["602401143452"] # Amazon EKS AMI account ID
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

#### The AMIs are specified in each of `the default_node_groups` `ami` field.
```hcl
default_node_groups = {
    compute = {
      ami                   = data.aws_ami.eks_node.image_id
      availability_zone_ids = ["usw2-az1", "usw2-az2"]
    }
    platform = {
      ami                   = data.aws_ami.eks_node.image_id
      availability_zone_ids = ["usw2-az1", "usw2-az2"]
    }
    gpu = {
      ami                   = data.aws_ami.eks_gpu_node.id
      availability_zone_ids = ["usw2-az1", "usw2-az2"]
    }
  }
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.2.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 3.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.60.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_domino_eks"></a> [domino\_eks](#module\_domino\_eks) | ./../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ami.eks_gpu_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.eks_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.2.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 3.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_domino_eks"></a> [domino\_eks](#module\_domino\_eks) | ./../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ami.eks_gpu_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.eks_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | AWS region for deployment. | `string` | `"us-west-2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_domino_eks"></a> [domino\_eks](#output\_domino\_eks) | Module domino\_eks output |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
