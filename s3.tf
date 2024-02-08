# Create a bucket for the static website and content
resource "aws_s3_bucket" "content_bucket" {
  force_destroy = true
  bucket = "${var.name}-static"
  tags = local.common_tags
}

#Create a bucket for cloudwatch logging
resource "aws_s3_bucket" "logging_bucket" {
  force_destroy = true
  bucket = "${var.name}-logging"
  
  tags = local.common_tags
}
#This section is needed to allow logging | ISSUE 1
resource "aws_s3_bucket_ownership_controls" "logging_oc" {
  bucket = aws_s3_bucket.logging_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
#This section is to enable SSE-KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "logging_sse" {
  bucket = aws_s3_bucket.logging_bucket.bucket
  rule {
    # bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cmk.arn
      sse_algorithm = "aws:kms"
    }
  }
  depends_on = [ aws_kms_key.cmk ]
}

#This section is to enable SSE-KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "content_sse" {
  bucket = aws_s3_bucket.content_bucket.bucket
  rule {
    # bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cmk.arn
      sse_algorithm = "aws:kms"
    }
  }
  depends_on = [ aws_kms_key.cmk ]
}

# #This section is to enable SSE-KMS
# resource "aws_s3_bucket_server_side_encryption_configuration" "logging_sse" {
#   bucket = aws_s3_bucket.logging_bucket.bucket
#   rule {
#     bucket_key_enabled = true
#   }
# }

# Not sure if this is needed??
resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.content_bucket.id
  index_document {
    suffix = "index.html"
  }
  depends_on = [ aws_s3_bucket.content_bucket ]
}

resource "aws_kms_key" "cmk" {
  description = "This key is to encrypt the s3 buckets"
  deletion_window_in_days = 10
}