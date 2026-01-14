terraform {
  required_version = ">=0.12.0"
  backend "s3" {
    key            = "prod/terraform.state"
    bucket         = "champion-terraform-backend-bucket"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-locking"
  }
}
