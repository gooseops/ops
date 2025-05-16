module "test_vpc" {
  providers = {
    aws = aws.us-east-2
  }

  source = "../"

  vpc_cidr_block = "10.0.0.0/16"
  subnets = [
    {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-2a"
      is_public         = true
    },
    {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-2b"
      is_public         = false
    }
  ]
}
