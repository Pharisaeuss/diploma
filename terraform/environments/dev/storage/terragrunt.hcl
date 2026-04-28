include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/storage"
}

dependency "iam" {
  config_path = "../iam"
  mock_outputs = {
    ec2_role_id = "mock-role-id"
  }
}

inputs = {
  ec2_role_id = dependency.iam.outputs.ec2_role_id
}