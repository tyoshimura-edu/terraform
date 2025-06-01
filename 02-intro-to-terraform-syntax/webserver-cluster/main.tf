provider "aws" {
#   region = "ap-northeast-1"
    region = "us-east-2" # Ohio 
}

resource "aws_instance" "example" {
    ami = "ami-0fb653ca2d3203ac1" 
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World!" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
    
    user_data_replace_on_change = true

    tags = {
        Name = "terraform-example-instance"
    }
}

resource "aws_autoscaling_group" "example" {
    # launch_configuration = aws_launch_configuration.example.name
    vpc_zone_identifier = data.aws_subnets.default.ids

    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"

    min_size             = 2
    max_size             = 10
    desired_capacity     = 2

    launch_template {
        id      = aws_launch_template.example.id
        version = "$Latest"
    }

    tag {
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true
    }
    lifecycle {
        create_before_destroy = true
    }
}

# resource "aws_launch_configuration" "example" {
#     image_id = "ami-0fb653ca2d3203ac1"
#     instance_type = "t2.micro"
#     security_groups = [aws_security_group.instance.id]
#     user_data = <<-EOF
#                 #!/bin/bash
#                 echo "Hello, World!" > index.html
#                 nohup busybox httpd -f -p ${var.server_port} &
#                 EOF
#     # Autoscaling Groupがある起動設定を使った場合に必須”
#     lifecycle {
#         create_before_destroy = true
#     }
# }

resource "aws_launch_template" "example" {
  name_prefix   = "example-"
  image_id      = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Hello, World!" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
  EOF
  )
}


data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

resource "aws_lb" "example" {
    name           = "terraform-alb-example"
    load_balancer_type = "application"
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port              = 80
    protocol          = "HTTP"

    # デフォルトではシンプルな404ページを返す
    default_action {
        type             = "fixed-response"
        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code  = 404
        }
    }
}

resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority     = 100

    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.asg.arn
    }

    condition {
        path_pattern {
            values = ["*"]
        }
    }
}

resource "aws_lb_target_group" "asg" {
    name     = "terraform-asg-example"
    port     = var.server_port
    protocol = "HTTP"
    vpc_id   = data.aws_vpc.default.id

    health_check {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 3
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }
}

resource "aws_security_group" "alb" {
    name = "terraform-example-alb"
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"
    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

variable "server_port" {
    description = "The port the server will use for HTTP"
    type        = number
    default     = 8080
}