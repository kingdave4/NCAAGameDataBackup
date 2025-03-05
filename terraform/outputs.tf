output "bucket_name" {
  description = "S3 Bucket for highlights"
  value       = aws_s3_bucket.highlights.bucket
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.my_ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.my_cluster.name
}

output "EventBridge_rule_name" {
  description = "EventBridge rule name"
  value       = aws_cloudwatch_event_rule.daily_schedule.name
}

output "mediaconvert_role_arn" {
  description = "MediaConvert IAM role ARN (if created)"
  value       = aws_iam_role.mediaconvert_role.arn
  # Only relevant if you define the mediaconvert_role resource in iam.tf
}
