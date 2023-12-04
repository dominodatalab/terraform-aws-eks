additional_node_groups = null
default_node_groups = {
  compute = {
    ami = "ami-07492d7cc3295213c"
    #    ami                   = "ami-0adf64856582fb168"

    instance_types = ["t3.micro"]
    volume = {
      size = 100
      type = "gp3"
    }

    availability_zone_ids = ["usw2-az1", "usw2-az2"]
    max_per_az            = 25
    #    min_per_az = 15
    #    desired_per_az = 20
  }
  gpu = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
  platform = {
    availability_zone_ids = ["usw2-az1", "usw2-az2"]
  }
}
