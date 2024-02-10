#By Obijah <ohbster@protonmail.com>

########
#Project Attributes
########
#The name to use for the resources
name = "ohbster-cloudwatch-terraform"
#Set the region for the project

#common tags to apply to resources
common_tags = {
  Environment = "dev"
  Version     = ".1"
  Owner       = "ohbster@protonmail.com"
}

#domain name
domain_name = "www.goldwatch.tv"
zone_name   = "goldwatch.tv"

# regions = [{
#   region = "us-east-1"
#   cidr   = "10.51.0.0/16"
#   },
#   {
#     region = "us-west-2"
#     cidr   = "10.52.0.0/16"
# }]
# region  = "us-east-1"
# region2 = "us-west-2"