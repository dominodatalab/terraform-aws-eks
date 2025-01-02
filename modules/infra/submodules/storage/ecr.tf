locals {
  encryption_type = var.kms_info.enabled ? "KMS" : "AES256"
  ecr_repos       = toset(["model", "environment"])

  # FIPS, GovCloud and China don't support pull through cache fully yet
  # https://docs.aws.amazon.com/AmazonECR/latest/userguide/pull-through-cache.html#pull-through-cache-considerations
  supports_pull_through_cache = data.aws_partition.current.partition == "aws" && !var.use_fips_endpoint
}

resource "aws_ecr_repository" "this" {
  for_each             = local.ecr_repos
  name                 = join("/", [var.deploy_id, each.key])
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = local.encryption_type
    kms_key         = local.kms_key_arn
  }

  force_delete = var.storage.ecr.force_destroy_on_deletion

  lifecycle {
    ignore_changes = [
      encryption_configuration,
    ]
  }
}

resource "aws_ecr_pull_through_cache_rule" "quay" {
  count                 = local.supports_pull_through_cache ? 1 : 0
  ecr_repository_prefix = "${substr(var.deploy_id, 0, 24)}/quay"
  upstream_registry_url = "quay.io"
}

resource "terraform_data" "pull_through_cache_deletion" {
  input = {
    region                = var.region
    ecr_repository_prefix = "${var.deploy_id}/quay"
    use_fips_endpoint     = var.use_fips_endpoint
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<-EOF
      set -ex -o pipefail
      for repo_name in calico/apiserver calico/csi calico/kube-controllers calico/node calico/node-driver-registrar calico/pod2daemon-flexvol calico/typha tigera/operator; do
        aws ecr delete-repository --force --repository-name "${self.input.ecr_repository_prefix}/$repo_name" > /dev/null || echo "Failed to delete repository $repo_name"
      done
    EOF
    interpreter = ["bash", "-c"]
    environment = {
      AWS_USE_FIPS_ENDPOINT = tostring(self.input.use_fips_endpoint)
      AWS_REGION            = self.input.region
    }
  }
}
