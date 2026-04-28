include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/network"
}

inputs = {
  zone = "eu-central-1a"
}