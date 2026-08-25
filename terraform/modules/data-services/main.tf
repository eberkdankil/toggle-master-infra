# ============================================================
# Módulo escrito e pronto, mas ainda NÃO é chamado por nenhum ambiente
# (ver comentário em terraform/environments/aws/main.tf). Provisiona os
# itens 3 e 4 dos requisitos técnicos do Tech Challenge: 3x RDS Postgres,
# 1x ElastiCache Redis, 1x tabela DynamoDB e 1x fila SQS.
# ============================================================

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project}-db-subnets"
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project}-redis-subnets"
  subnet_ids = var.private_subnet_ids
}

# SG único pras 3 instâncias RDS + Redis. Libera 5432/6379 só de dentro da
# VPC — apertar depois pra só a SG dos nodes do EKS quando ele existir.
resource "aws_security_group" "data" {
  name_prefix = "${var.project}-data-"
  description = "Acesso aos bancos/cache do ToggleMaster a partir da VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "Postgres a partir da VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Redis a partir da VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-data-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "auth" {
  identifier             = "${var.project}-auth"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "auth_db"
  username               = var.auth_db_username
  password               = var.auth_db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.data.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "${var.project}-auth-db"
  }
}

resource "aws_db_instance" "flags" {
  identifier             = "${var.project}-flags"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "flags_db"
  username               = var.flags_db_username
  password               = var.flags_db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.data.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "${var.project}-flags-db"
  }
}

resource "aws_db_instance" "targeting" {
  identifier             = "${var.project}-targeting"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "targeting_db"
  username               = var.targeting_db_username
  password               = var.targeting_db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.data.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "${var.project}-targeting-db"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id         = "${var.project}-redis"
  engine             = "redis"
  node_type          = var.redis_node_type
  num_cache_nodes    = 1
  port               = 6379
  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.data.id]

  tags = {
    Name = "${var.project}-redis"
  }
}

resource "aws_dynamodb_table" "analytics" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  tags = {
    Name = var.dynamodb_table_name
  }
}

resource "aws_sqs_queue" "events" {
  name = var.sqs_queue_name

  tags = {
    Name = var.sqs_queue_name
  }
}
