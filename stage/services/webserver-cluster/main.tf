provider "aws" {
    region = "eu-west-1"
}

# replace the instance with auto scaling group
/*
resource "aws_instance" "one-server" {
    ami = "ami-00f499a80f4608e1b"
    instance_type = "t3.nano"
    vpc_security_group_ids = [aws_security_group.access-group.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
    
    tags = {
        Name = "label-server"
    }
}
*/

resource "aws_security_group" "access-group" {
    name = "label-server-access-group"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_launch_template" "redeem" {
    image_id = "ami-00f499a80f4608e1b"
    instance_type = "t3.nano"
    security_groups = [aws_security_group.access-group.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
/*
    lifecycle {
        create_before_destroy = true
    }
*/
}

resource "aws_autoscaling_group" "redeem" {
    vpc_zone_identifier = data.aws_subnet_ids.default.ids

    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"

    min_size = 2
    max_size = 5

    launch_template {
      id = aws_launch_template.redeem.id
      version = "$Latest"
    }

    tag {
        key = "Name"
        value = "redeem-asg"
        propagate_at_launch = true
    }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}



resource "aws_lb" "redeem" {
    name = "redeem-asg"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids
    security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "asg" {
    name = "redeem-asg"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.redeem.arn
    port = 80
    protocol = "HTTP"

    # By default, return a simple 404 page
    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

resource "aws_security_group" "alb" {
    name = "redeem-practise-alb"

    # Allow inbound HTTP requests
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow all outbound requests
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
    values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}



/*
terraform {
    backend "s3" {
        bucket = "arm-running"
        region = "eu-west-1"
        key = "stage/services/webserver-cluster/terraform.tfstate"
        dynamodb_table = "arm-running-locks"
        encrypt = true
    }
}
*/

