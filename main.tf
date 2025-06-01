provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_instance" "example" {
    ami = "ami-0c1638aa346a43fe8"
    # ami-0ca6e4ffd34c17d86 
    # Microsoft Windows Server 2022 Base ami-0ca6e4ffd34c17d86 (64 ビット (x86)) Microsoft Windows 2022 Datacenter edition. [English]
    instance_type = "t2.micro"
}