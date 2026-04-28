include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/iam"
}

inputs = {
  env = "dev"
}