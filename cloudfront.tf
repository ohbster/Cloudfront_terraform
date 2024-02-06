/*requirements
--cloudfront-
-create bucket
-create cloudfront distribution
-create origin access controll
-create policy
custom SSL certificate
Add Alternate domain name(CNAME)
allowed HTTP methods (GET,HEAD)
cache policy and origin 
cachingOptimized
price class(NA and EU only)
Supported HTTP (HTTP/2)
IPv6 off

-route53-
add A record pointing to cloudfront
*/

/*misc
redirect http to https
compress objects automaticcaly
*/

/* Policy

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
                "Resource": "arn:aws:s3:::ohbster-cloudfront-tester/*",
                "Condition": {
                    "StringEquals": {
                      "AWS:SourceArn": "arn:aws:cloudfront::378576100664:distribution/E2JKKQIEP5DV3O"
                    }
                }
            }
        ]
      }
*/
locals {
    s3_origin_id = "someS3Origin"
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.name}-oac"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    #domain_name              = aws_s3_bucket.b.bucket_regional_domain_name
    #domain_name = var.domain_name
    domain_name = aws_s3_bucket.content_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

#   logging_config {
#     include_cookies = false
#     #bucket          = "mylogs.s3.amazonaws.com"
#     #bucket = "${aws_s3_bucket.logging_bucket.bucket}.s3.amazonaws.com"
#     bucket = aws_s3_bucket.logging_bucket.bucket_domain_name
#     prefix          = "cloudfront-logs"
#   }

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

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

#   # Cache behavior with precedence 0
#   ordered_cache_behavior {
#     path_pattern     = "/content/immutable/*"
#     allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#     cached_methods   = ["GET", "HEAD", "OPTIONS"]
#     target_origin_id = local.s3_origin_id

#     forwarded_values {
#       query_string = false
#       headers      = ["Origin"]

#       cookies {
#         forward = "none"
#       }
#     }

#     min_ttl                = 0
#     default_ttl            = 86400
#     max_ttl                = 31536000
#     compress               = true
#     viewer_protocol_policy = "redirect-to-https"
#   }

#   # Cache behavior with precedence 1
#   ordered_cache_behavior {
#     path_pattern     = "/content/*"
#     allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = local.s3_origin_id

#     forwarded_values {
#       query_string = false

#       cookies {
#         forward = "none"
#       }
#     }

#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#     compress               = true
#     viewer_protocol_policy = "redirect-to-https"
#   }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    #cloudfront_default_certificate = true
    acm_certificate_arn = aws_acm_certificate.certificate.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
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
                      # "AWS:SourceArn": "arn:aws:cloudfront::378576100664:distribution/E2JKKQIEP5DV3O"
                      "AWS:SourceArn": "${aws_cloudfront_distribution.s3_distribution.arn}"
                      
                    }
                }
            }
        ]
      }
#     {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "PublicReadGetObject",
#             "Effect": "Allow",
#             "Principal": "*",
#             "Action": "s3:GetObject",
#             "Resource": "${aws_s3_bucket.bucket.arn}/*"
#         }
#     ]
# }
)
depends_on = [ aws_cloudfront_distribution.s3_distribution ]
}