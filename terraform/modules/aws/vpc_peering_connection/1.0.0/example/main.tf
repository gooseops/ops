module "vpc_peering_example" {
  source = "../"

  providers = {
    aws.requester = aws
    aws.accepter  = aws.us_west_1
  }


  requester_vpc_id = "vpc-abc123"
  accepter_vpc_id  = "vpc-def456"
  accepter_region  = "us-west-2"

  tags = {
    Name        = "vpc-peering-example"
    Environment = "example"
  }
}
