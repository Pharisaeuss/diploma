include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/storage"
}

dependency "iam" {
  config_path = "../iam"
  mock_outputs = {
    app_node_role_id = "mock-role-id"
  }
}

inputs = {
  app_node_role_id = dependency.iam.outputs.app_node_role_id
}