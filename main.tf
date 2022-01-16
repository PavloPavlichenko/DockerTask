provider "aws" {
    region = "eu-north-1"
}

resource "aws_instance" "web" {
    ami                    = "ami-092cce4a19b438926"      //Ubuntu 20
    instance_type          = "t3.micro"
    key_name               = "pasha-key-stockholm"
    vpc_security_group_ids = [aws_security_group.web.id]
    iam_instance_profile   = aws_iam_instance_profile.logging_profile.name
    user_data              = "${file("docker.sh")}"

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

resource "aws_iam_role" "logging_role" {
  name = "logging_role"
  assume_role_policy = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "logging_policy_role" {
  name = "logging_policy_role"
  roles = [aws_iam_role.logging_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_instance_profile" "logging_profile" {
  name = "logging_profile"
  role = aws_iam_role.logging_role.name
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name                = "cpu-utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []
  dimensions = {
    InstanceId = aws_instance.web.id
  }
}
