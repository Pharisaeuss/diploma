locals {
  environment         = "stage"
  vpc_cidr            = "10.2.0.0/16"
  instance_type       = "t3.small"
  asg_min_size        = 1
  asg_max_size        = 3
  multi_az_db         = false
  nat_count           = 1
  deletion_protection = false
}