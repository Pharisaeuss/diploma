locals {
  environment         = "prod"
  instance_type       = "c7i-flex.large"
  asg_min_size        = 2
  asg_max_size        = 10
  multi_az_db         = true
  nat_count           = 2
  deletion_protection = true
}