output "auth_db_endpoint" {
  value = aws_db_instance.auth.address
}

output "flags_db_endpoint" {
  value = aws_db_instance.flags.address
}

output "targeting_db_endpoint" {
  value = aws_db_instance.targeting.address
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.analytics.name
}

output "sqs_queue_url" {
  value = aws_sqs_queue.events.url
}
