# Bucket name for application configuration.
output "bucket_name" {
  description = "Name of the private media bucket."
  value       = aws_s3_bucket.media.bucket
}

# Bucket ARN for IAM policies and access configuration.
output "bucket_arn" {
  description = "ARN of the private media bucket."
  value       = aws_s3_bucket.media.arn
}

# Bucket regional endpoint for application configuration.
output "bucket_region" {
  description = "AWS region containing the media bucket."
  value       = aws_s3_bucket.media.region
}
