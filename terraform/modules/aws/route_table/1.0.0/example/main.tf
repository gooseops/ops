module "example_route_table" {
  source = "../"

  vpc_id     = "example_id"
  subnet_ids = ["example-subnetid-01", "example-subnetid-02"]

  routes = [
    {
      destination_cidr_block    = "10.0.0.0/16"
      vpc_peering_connection_id = "example-vpc-peer-conn-id"
    }
  ]
}
