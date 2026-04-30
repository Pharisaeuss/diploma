include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/monitoring"
}

dependency "app_cluster" {
  config_path = "../app_cluster"
  mock_outputs = {
    asg_name       = "mock-asg-app-dev"
    alb_arn_suffix = "app/mock-alb-name/1234567890abcdef"
  }
}

dependency "rds" {
  config_path = "../rds"
  mock_outputs = {
    db_identifier = "mock-streamlit-db-dev"
  }
}

inputs = {
  asg_name       = dependency.app_cluster.outputs.asg_name
  alb_arn_suffix = dependency.app_cluster.outputs.alb_arn_suffix
  db_identifier  = dependency.rds.outputs.db_identifier
}