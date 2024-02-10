# Create a Customer Managed Key
# This is to fix ISSUE #2
resource "aws_kms_key" "cmk" {
  description = "This key is to encrypt the s3 buckets"
  deletion_window_in_days = 10
  #This will satisfy ISSUE #10
  enable_key_rotation = true
  multi_region = true
}

resource "aws_kms_alias" "cmk_alias" {
  name = "alias/cloudfront-terraform-cmk"
  target_key_id = aws_kms_key.cmk.id
  
}

# Create a policy to only allow cloudfront access to the key
# resource "aws_kms_key_policy" "name" {
  
# }
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# Working

# {
#     "Version": "2012-10-17",
#     "Id": "key-default-1",
#     "Statement": [
#         {
#             "Sid": "Enable IAM User Permissions",
#             "Effect": "Allow",
#             "Principal": {
#                 "AWS": "arn:aws:iam::378576100664:root"
#             },
#             "Action": "kms:*",
#             "Resource": "*"
#         },
#         {
#             "Sid": "Enable Cloudfront Permissions",
#             "Effect": "Allow",
#             "Principal": {
#                 "Service": "cloudfront.amazonaws.com"
#             },
#             "Action": "kms:Decrypt",
#             "Resource": "*",
#             "Condition": {
#                 "StringEquals": {
#                     "AWS:SourceArn": "arn:aws:cloudfront::${local.account_id}:distribution/${aws_cloudfront_distribution.s3_distribution.id}"
#                 }
#             }
#         }
#     ]
# }

resource "aws_kms_key_policy" "cmk_policy" {
  key_id = aws_kms_key.cmk.id
  policy = jsonencode(
    {
    "Version":"2012-10-17",
    "Id": "key-default-1",
    "Statement" : [
      {
          "Sid": "Enable IAM User Permissions",
          "Effect": "Allow",
          "Principal": {
              "AWS": "arn:aws:iam::${local.account_id}:root"
          },
          "Action": "kms:*",
          "Resource": "*"
      },
      {
        "Sid" : "Enable Cloudfront Permissions",
        "Effect": "Allow",
        "Principal": {
            "Service": [
                "cloudfront.amazonaws.com"
            ]
          },
        "Action": [
            "kms:Decrypt",
            "kms:Encrypt",
            "kms:GenerateDataKey*"
        ],
        "Resource": "*",
        "Condition":{
            "StringEquals":{
                  "aws:SourceArn": "arn:aws:cloudfront::${local.account_id}:distribution/${aws_cloudfront_distribution.s3_distribution.id}"
            }
        }
    }]
    }
  )
}