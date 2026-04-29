include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/rds"
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    db_subnet_ids = ["subnet-mock1", "subnet-mock2"]
    rds_sg_id     = "sg-mock-rds"
  }
}

inputs = {
  db_username = "postgres"
  db_name     = "postgres"

  db_subnet_ids = dependency.network.outputs.db_subnet_ids
  rds_sg_id     = dependency.network.outputs.rds_sg_id
}