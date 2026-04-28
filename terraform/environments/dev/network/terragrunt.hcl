include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/network"
}

inputs = {
  env  = "dev"
  zone = "eu-central-1a"
}