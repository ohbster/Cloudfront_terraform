output "distribution_id" {
  value = aws_cloudfront_distribution.s3_distribution.id
}
output "url" {
    value = [aws_cloudfront_distribution.s3_distribution.aliases]
}