/*requirements
--cloudfront-
-create bucket
-create cloudfront distribution
-create origin access controll
-create policy
-custom SSL certificate
-Add Alternate domain name(CNAME)
-allowed HTTP methods (GET,HEAD)
-cache policy and origin 
cachingOptimized
-price class(NA and EU only)
Supported HTTP (HTTP/2)
IPv6 off

-route53-
-add A record pointing to cloudfront
*/

/*misc
redirect http to https
compress objects automaticcaly
*/

locals {
    s3_origin_id = "someS3Origin"
}

#Explore using origin access ID instead.
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.name}-oac"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  web_acl_id = aws_wafv2_web_acl.waf.arn
  origin {
    domain_name = aws_s3_bucket.content_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket = aws_s3_bucket.logging_bucket.bucket_domain_name
    prefix          = "cloudfront-logs/"
  }

  aliases = ["${var.domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    # The is set to "redirect-to-https to fix ISSUE #9"
    # ISSUE #9 - Distribution allows unencrypted communications
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = local.common_tags

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.certificate.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${self.id} --paths '/*'"
  }

  depends_on = [ aws_s3_bucket.content_bucket,aws_s3_bucket.logging_bucket,aws_acm_certificate.certificate ]
}

resource "aws_s3_bucket_policy" "policy" {
  
  bucket = aws_s3_bucket.content_bucket.id
  policy = jsonencode(
    {
        "Version": "2008-10-17",
        "Id": "PolicyForCloudFrontPrivateContent",
        "Statement": [
            {
                "Sid": "AllowCloudFrontServicePrincipal",
                "Effect": "Allow",
                "Principal": {
                    "Service": "cloudfront.amazonaws.com"
                },
                "Action": "s3:GetObject",
                "Resource": "${aws_s3_bucket.content_bucket.arn}/*",
                "Condition": {
                    "StringEquals": {
                      "AWS:SourceArn": "${aws_cloudfront_distribution.s3_distribution.arn}"
                      
                    }
                }
            }
        ]
      }
)
depends_on = [ aws_cloudfront_distribution.s3_distribution ]
}

resource "aws_s3_bucket_policy" "logging_policy" {
  
  bucket = aws_s3_bucket.logging_bucket.id
  policy = jsonencode(
    {
        "Version": "2008-10-17",
        "Id": "PolicyForCloudFrontPrivateContent",
        "Statement": [
            {
                "Sid": "AllowCloudFrontServicePrincipal",
                "Effect": "Allow",
                "Principal": {
                    "Service": "cloudfront.amazonaws.com"
                },
                "Action": "s3:PutObject",
                "Resource": "${aws_s3_bucket.logging_bucket.arn}/*",
                "Condition": {
                    "StringEquals": {
                      "AWS:SourceArn": "${aws_cloudfront_distribution.s3_distribution.arn}"
                      
                    }
                }
            }
        ]
      }
)
depends_on = [ aws_cloudfront_distribution.s3_distribution ]
}