# Create a Customer Managed Key
# This is to fix ISSUE #2
resource "aws_kms_key" "cmk" {
  description = "This key is to encrypt the s3 buckets"
  deletion_window_in_days = 10
  #This will satisfy ISSUE #10
  enable_key_rotation = true
}

# Create a policy to only allow cloudfront access to the key
# resource "aws_kms_key_policy" "name" {
  
# }