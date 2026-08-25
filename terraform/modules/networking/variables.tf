variable "project" {
  description = "Prefixo usado no Name das tags."
  type        = string
  default     = "togglemaster"
}

variable "cluster_name" {
  description = <<-EOT
    Nome que o cluster EKS terá quando for criado (ainda não existe nesta fase).
    Usado só para as tags kubernetes.io/cluster/<nome> nas subnets, exigidas
    pelo EKS/AWS Load Balancer Controller pra descobrir automaticamente onde
    colocar os LoadBalancers — preparar agora evita ter que retaguear depois.
  EOT
  type        = string
  default     = "togglemaster"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability Zones a usar. Pelo menos 2 são exigidas pelo EKS."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}
