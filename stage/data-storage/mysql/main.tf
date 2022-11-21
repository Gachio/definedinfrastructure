provider "aws" {
  region = "eu-west-1"
}

resource "aws_db_instance" "example" {
  identifier_prefix = "arm-filled-up"
  engine = "mysql"
  allocated_storage = 5
  instance_class = "db.t2.micro"
  name = "example_database"
  username = "admin"

  # How should I set the password?
  password = var.db_password
}

data "aws_secretsmanager_secret" "db_password" {
  name = "mysql-master-password-stage"
}

data "aws_secretsmanager_secret_version" "db_password" {
    secret_id = data.aws_secretsmanager_secret.db_password.id
   
}

terraform {
    backend "s3" {
        bucket = "arm-running"
        region = "eu-west-1"
        key = "stage/data-stores/mysql/terraform.tfstate"
        dynamodb_table = "arm-running-locks"
        encrypt = true
    }
}