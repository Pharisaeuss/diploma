locals {
  environment         = "dev"
  instance_type       = "t3.micro"
  asg_min_size        = 1
  asg_max_size        = 2
  multi_az_db         = false
  nat_count           = 1
  deletion_protection = false
}