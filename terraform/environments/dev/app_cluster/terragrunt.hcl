include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/app_cluster"
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    vpc_id         = "vpc-mock"
    asg_subnet_ids  = ["subnet-mock-asg-1", "subnet-mock-asg-2"]
    alb_subnet_ids = ["subnet-mock-alb-1", "subnet-mock-alb-2"]
    asg_sg_id      = "sg-mock-asg"
    alb_sg_id      = "sg-mock-alb"
  }
}

dependency "iam" {
  config_path = "../iam"
  mock_outputs = {
    ec2_instance_profile_name = "mock-instance-profile"
  }
}

dependency "storage" {
  config_path = "../storage"
  mock_outputs = {
    alb_logs_bucket_id = "mock-bucket-id"
  }
}

inputs = {
  machine_type = "t3.micro"

  # Від мережі
  vpc_id         = dependency.network.outputs.vpc_id
  asg_subnet_ids  = dependency.network.outputs.asg_subnet_ids
  alb_subnet_ids = dependency.network.outputs.alb_subnet_ids
  asg_sg_id      = dependency.network.outputs.asg_sg_id
  alb_sg_id      = dependency.network.outputs.alb_sg_id

  # Від IAM
  iam_instance_profile_name = dependency.iam.outputs.ec2_instance_profile_name

  # Від Storage
  alb_logs_bucket_id = dependency.storage.outputs.alb_logs_bucket_id
}