############################################
# Basic configuration for s3
# Create a bucket for the static website and content
resource "aws_s3_bucket" "content_bucket" {
  force_destroy = true
  bucket = "${var.name}-static"
  tags = local.common_tags
}

# Not sure if this is needed??
resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.content_bucket.id
  index_document {
    suffix = "index.html"
  }
  depends_on = [ aws_s3_bucket.content_bucket ]
}

############################################
# Security Enhancements for TFSec

# This section is needed to allow logging 
# Satisfy ISSUE #1
# Create a bucket for cloudwatch logging
resource "aws_s3_bucket" "logging_bucket" { #tfsec:ignore:aws-s3-enable-bucket-logging
  force_destroy = true
  bucket = "${var.name}-logging"
  
  tags = local.common_tags
}

resource "aws_s3_bucket_ownership_controls" "logging_oc" {
  bucket = aws_s3_bucket.logging_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
# This satisfies ISSUE #5
# !!!WARNING!!!
# IF YOU SEND YOUR LOGS INTO THE SAME BUCKET YOU ARE LOGGING
# THE BUCKET SIZE WILL GROW EXPONENTIALLY AND SO WILL YOUR BILL 
# Be careful here.

resource "aws_s3_bucket_logging" "logging_bucket" {
  bucket = aws_s3_bucket.content_bucket.id
  target_bucket = aws_s3_bucket.logging_bucket.id
  target_prefix = "s3-log/"

}

###########################
# Public access block 
# Satisfy ISSUE #4
resource "aws_s3_bucket_public_access_block" "content_public_block" {
  bucket = aws_s3_bucket.content_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [ aws_s3_bucket.content_bucket ]
}
resource "aws_s3_bucket_public_access_block" "logging_public_block" {
  bucket = aws_s3_bucket.logging_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [ aws_s3_bucket.logging_bucket ]
}

#########################
# This section is to enable SSE-KMS
# Satisfy ISSUE #2 #3
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

#########################
# Create Bucket versioning
# Satisfy ISSUE #6
resource "aws_s3_bucket_versioning" "content_versioning" {
  bucket = aws_s3_bucket.content_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_versioning" "logging_versioning" {
  bucket = aws_s3_bucket.logging_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
