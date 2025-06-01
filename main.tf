provider "aws" {
#   region = "ap-northeast-1"
    region = "us-east-2" # Ohio 
}

resource "aws_instance" "example" {
    ami = "ami-0fb653ca2d3203ac1" 
    # ami = "ami-026c39f4021df9abe" # Ubuntu Server 24.04 LTS (HVM), SSD Volume Type [Japanese]
    # "ami-0c1638aa346a43fe8" # Amazon Linux 2 AMI (HVM), SSD Volume Type [Japanes
    # ami-026c39f4021df9abe (64 ビット (x86)) Ubuntu Server 24.04 LTS (HVM), SSD Volume Type [Japanese]
    # ami-0ca6e4ffd34c17d86 
    # Microsoft Windows Server 2022 Base ami-0ca6e4ffd34c17d86 (64 ビット (x86)) Microsoft Windows 2022 Datacenter edition. [English]
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World!" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
    
    user_data_replace_on_change = true

    tags = {
        Name = "terraform-example-instance"
    }
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"
    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

