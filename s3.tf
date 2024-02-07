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
#This section is needed to allow logging
resource "aws_s3_bucket_ownership_controls" "s3_oc" {
  bucket = aws_s3_bucket.logging_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Not sure if this is needed??
resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.content_bucket.id
  index_document {
    suffix = "index.html"
  }
  depends_on = [ aws_s3_bucket.content_bucket ]
}
