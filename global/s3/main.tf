provider "aws" {
    region = "eu-west-1"
}

resource "aws_s3_bucket" "arm_state" {
    #bucket = "arm-running"
    bucket = var.bucket_name
    force_destroy = true

    # Enable versioning to see the full revision history of state files
    
    versioning {
        enabled = false
    }
   

    # Enable server-side encryption by default
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}

resource "aws_dynamodb_table" "arm_locks" {
    #name = "arm-running-locks"
    name = var.table_name
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}

/*
terraform {
    backend "s3" {
        key = "geo/s3/terraform.tfstate"
    }
}
*/
/*
output "s3_bucket_arn" {
    value = aws_s3_bucket.arm_state.arn
    description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
    value = aws_dynamodb_table.arm_locks.name
    description = "The name of the DynamoDB table"
}
*/
