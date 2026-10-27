# Name prefix for the private media bucket.
variable "bucket_name" {
  description = "Globally unique S3 bucket name for Bagisto media."
  type        = string
}

# Common tags applied to the bucket.
variable "tags" {
  description = "Tags applied to S3 resources."
  type        = map(string)
  default     = {}
}

# Number of days before noncurrent object versions expire.
variable "noncurrent_version_expiration_days" {
  description = "Retention period for older object versions."
  type        = number
  default     = 90
}
