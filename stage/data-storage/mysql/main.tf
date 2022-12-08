  provider "aws" {
    region = "eu-west-1"
  }

  resource "random_password" "master" {
    length           = 16
    special          = true
    override_special = "_!%^"
  }


  resource "aws_secretsmanager_secret" "password" {
    name = "mysql-master-password-stage"
  }

  resource "aws_secretsmanager_secret_version" "password" {
    secret_id = aws_secretsmanager_secret.password.id
    secret_string = random_password.master.result
  }


  data "aws_secretsmanager_secret" "db_password" {
    name = "mysql-master-password-stage"
    depends_on = [
      aws_secretsmanager_secret.password
    ]
  }

  data "aws_secretsmanager_secret_version" "db_password" {
      secret_id = data.aws_secretsmanager_secret.db_password.id  
  }

  resource "aws_db_instance" "tutorial" {
    identifier_prefix = "arm-filled-up"
    engine = "mysql"
    allocated_storage = 5
    instance_class = "db.t2.micro"
    name = "tutorial_database"
    #username = "admin"

    # How should I set the password?
    #password = data.aws_secretsmanager_secret_version.db_password
    username = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["username"]
    password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
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