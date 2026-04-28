variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "zone" {
  description = "Specific availability zone for the ASG subnet"
  type        = string
}