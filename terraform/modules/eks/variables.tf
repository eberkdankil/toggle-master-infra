variable "cluster_name" {
  type = string
}

variable "lab_role_arn" {
  description = "ARN da LabRole do AWS Academy — reusada tanto pro cluster quanto pro node group, já que o Academy não permite criar roles/policies de IAM próprias."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets onde o cluster (control plane) e o node group vivem. Nesta fase são as subnets públicas (decisão consciente pra evitar o custo do NAT Gateway)."
  type        = list(string)
}

variable "endpoint_public_access" {
  type    = bool
  default = true
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}
