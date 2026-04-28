variable "env" {
  description = "Environment name"
  type        = string
}

variable "db_username" {
  description = "Database Master Username"
  type        = string
  default     = "streamlit_admin"
}

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "streamlit_db"
}

variable "db_subnet_ids" {
  description = "List of private subnet IDs for the database"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security Group ID for RDS"
  type        = string
}