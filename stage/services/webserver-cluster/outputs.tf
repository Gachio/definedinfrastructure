
output "alb_dns_name" {
    value = aws_lb.redeem.dns_name
    description = "The domain name of the load balancer"
}

/*
output "public_ip" {
    value = aws_instance.one-server.public_ip
    description = "The public IP address of the web server"
}
*/