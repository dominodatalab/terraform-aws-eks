deploy_id        = "plantest010"
region           = "us-west-2"
ssh_pvt_key_path = "domino.pem"

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
  additional_policies = [<<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
      "Sid": "AllowAll",
      "Effect": "Allow",
      "Principal": "arn:${data.aws_partition.current.partition}:iam::123457890:root",
      "Action": ["kms:Decrypt"],
      "Resource": "*"
   }
  ]
}
EOF
  ]
}
