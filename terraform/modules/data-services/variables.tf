variable "project" {
  type    = string
  default = "togglemaster"
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  description = "Usado na security group das bases pra liberar acesso de dentro da VPC. Trocar por uma referência à SG dos nodes do EKS assim que ele existir."
  type        = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "auth_db_username" {
  type    = string
  default = "auth_user"
}

variable "auth_db_password" {
  type      = string
  sensitive = true
}

variable "flags_db_username" {
  type    = string
  default = "flags_user"
}

variable "flags_db_password" {
  type      = string
  sensitive = true
}

variable "targeting_db_username" {
  type    = string
  default = "targeting_user"
}

variable "targeting_db_password" {
  type      = string
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "sqs_queue_name" {
  type    = string
  default = "togglemaster-events"
}

variable "dynamodb_table_name" {
  type    = string
  default = "ToggleMasterAnalytics"
}
