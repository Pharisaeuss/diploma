# variable "region" {
#   description = "AWS Region"
#   type        = string
# }
variable "env" {
  description = "Environment name"
  type        = string
}
variable "region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1" 
}