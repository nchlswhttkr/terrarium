output "vpc_subnet_id" {
  value = aws_subnet.main.id
}
output "task_definition_arn" {
  value = aws_ecs_task_definition.terraria.arn
}
output "ecs_cluster_arn" {
  value = aws_ecs_cluster.terrarium.arn
}
output "config_s3_bucket" {
  value = aws_s3_bucket.config.bucket
}
