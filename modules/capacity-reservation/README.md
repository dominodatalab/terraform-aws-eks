# capacity-reservation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ec2_capacity_reservation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_capacity_reservation) | resource |
| [terraform_data.describe_capacity_reservation](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_availability_zone.zone_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zone) | data source |
| [aws_ec2_instance_type_offerings.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type_offerings) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_instance_capacity"></a> [instance\_capacity](#input\_instance\_capacity) | Creates a capacity reservation for each instance\_type on each zone.<br/>    instance\_types        = List of instance types to create a capacity reservation for.<br/>    capacity              = Number of instances to reserve<br/>    availability\_zone\_ids = List of azs to create a capacity reservation in.<br/>    } | <pre>map(object({<br/>    instance_types        = list(string)<br/>    capacity              = number<br/>    availability_zone_ids = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_capacity_reservation"></a> [capacity\_reservation](#output\_capacity\_reservation) | Capacity Reservations information. |
<!-- END_TF_DOCS -->

## Usage

Create the following files:
* `main.tf`. :warning: Update with intended module version(using `main` in the example below).
* `capacity.auto.tfvars`. :warning: Update with appropriate values.

`main.tf`

```hcl
variable "instance_capacity" {
  description = "Additional EKS managed node groups definition."
  type = map(object({
    instance_types        = list(string)
    capacity              = number
    availability_zone_ids = list(string)
  }))
  default = {}
}

variable "region" {
  default = "us-west-2"
}


module "capacity_reservation" {
  source      = "github.com/dominodatalab/terraform-aws-eks.git//modules/capacity-reservation?ref=main"
  instance_capacity = var.instance_capacity
  region      = var.region
}

output "capacity_reservation" {

  value = module.capacity_reservation.capacity_reservation
}

provider "aws" {
  region = var.region
}
```

`capacity.auto.tfvars`

```hcl
region = "us-west-2"
instance_capacity = {
  custom_1 = {
    availability_zone_ids = ["usw2-az1", "usw2-az4"]
    capacity = 4
    instance_types = ["trn1.2xlarge"]
  }
  custom_2 = {
    availability_zone_ids = ["usw2-az1", "usw2-az4"]
    capacity = 4
    instance_types = ["i4i.32xlarge"]
  }
  custom_3 = {
    availability_zone_ids = ["usw2-az1", "usw2-az3"]
    capacity = 4
    instance_types = ["p3.8xlarge"]
  }
}
```
