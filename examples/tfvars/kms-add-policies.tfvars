deploy_id        = "plantest010"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

## The following  (default_node_groups,additional_node_groups) will ALSO need to be set in the nodes.tfvars
default_node_groups = {
  compute = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  gpu = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  platform = {
    "availability_zone_ids" = ["usw2-az1", "usw2-az2"]
  }
}

kms = {
  enabled = true
  additional_policies = [<<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
      "Sid": "AllowAll",
      "Effect": "Allow",
      "Principal": "arn:aws:iam::123457890:root",
      "Action": ["kms:Decrypt"],
      "Resource": "*"
   }
  ]
}
EOF
  ]
}
