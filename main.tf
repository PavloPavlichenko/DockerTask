provider "aws" {
    region = "eu-north-1"
}

resource "aws_instance" "web" {
    ami                    = "ami-092cce4a19b438926"      //Ubuntu 20
    instance_type          = "t3.micro"
    key_name               = "pasha-key-stockholm"
    vpc_security_group_ids = [aws_security_group.web.id]
    user_data              = <<EOF
#!/bin/bash

apt-get update
apt-get install \
    ca-certificates \
        curl \
            gnupg \
                lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io -y

docker run -d -p 80:80 ipashkayounot/git_sync:latest
docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup -i 20

EOF

    tags = {
      Name  = "web"
      Owner = "Pasha Pavlichenko"
    }
}

resource "aws_security_group" "web" {
    name        = "WebServer-SG"
    description = "SG for web server 80 443"

    ingress {
      description = "Allow HTTP port"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      description = "Allow HTTPS port"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      description = "Allow SSH port"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      description = "Allow all ports"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name  = "Devops Task SG"
      Owner = "Pasha Pavlichenko"
    }
}
