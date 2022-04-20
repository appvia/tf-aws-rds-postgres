terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

module "db" {
  source = "../"

  identifier             = "my-test-rds-module"
  instance_class         = "db.t4g.micro"
  region                 = "eu-west-2"
  vpc_id                 = "vpc-abc123def456ghi789"
  subnet_ids             = ["subnet-123", "subnet-456", "subnet-789"]
  sg_ingress_cidr_blocks = ["10.0.0.0/24"]
}
