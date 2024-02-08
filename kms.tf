# Create a Customer Managed Key
# This is to fix ISSUE #2
resource "aws_kms_key" "cmk" {
  description = "This key is to encrypt the s3 buckets"
  deletion_window_in_days = 10
}