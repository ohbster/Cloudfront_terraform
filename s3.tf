resource "aws_s3_bucket" "content_bucket" {
  force_destroy = true
  bucket = "${var.name}-static"
}
resource "aws_s3_bucket" "logging_bucket" {
  force_destroy = true
  bucket = "${var.name}-logging"
}

resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.content_bucket.id
  index_document {
    suffix = "index.html"
  }
  depends_on = [ aws_s3_bucket.content_bucket ]
}

# resource "aws_s3_bucket_policy" "cloudfront_bucket_policy" {
  
#   bucket = aws_s3_bucket.content_bucket.id
#   policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "PublicReadGetObject",
#             "Effect": "Allow",
#             "Principal": "*",
#             "Action": "s3:GetObject",
#             "Resource": "${aws_s3_bucket.content_bucket.arn}/*"
#         }
#     ]
# })
# depends_on = [ aws_s3_bucket.content_bucket ]
# }
