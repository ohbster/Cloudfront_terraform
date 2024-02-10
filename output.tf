output "distribution_id" {
  value = aws_cloudfront_distribution.s3_distribution.id
}
output "url" {
  value = [aws_cloudfront_distribution.s3_distribution.aliases]
}
output "bucket_name" {
  value = aws_s3_bucket.content_bucket.bucket
}