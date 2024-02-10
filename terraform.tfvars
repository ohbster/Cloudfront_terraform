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

