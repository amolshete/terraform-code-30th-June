terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

terraform {
  
  backend "s3" {
    bucket = "terraform-state-file-bucket-30th-june"
    key    = "terraform-infra-file.tf"
    region = "ap-south-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}


# resource "aws_instance" "web" {
#   ami           = "ami-0f5ee92e2d63afc18"
#   instance_type = "t2.micro"
#   key_name = "linux-os-key"


#   tags = {
#     Name = "HelloWorld",
#     tier = "frontend"
#   }
# }


# resource "aws_eip" "lb" {
#   instance = aws_instance.web.id
# }

# creating the mumbai vpc
resource "aws_vpc" "mumbai-vpc" {
cidr_block = "10.10.0.0/16"

tags = {
    Name = "Mumbai-VPC"
  } 
}

# creating the subnet resoruces 

resource "aws_subnet" "mumbai-subnet-1a" {
  vpc_id     = aws_vpc.mumbai-vpc.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Mumbai-subnet-1a"
  }
}

resource "aws_subnet" "mumbai-subnet-1b" {
  vpc_id     = aws_vpc.mumbai-vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Mumbai-subnet-1b"
  }
}

resource "aws_subnet" "mumbai-subnet-1c" {
  vpc_id     = aws_vpc.mumbai-vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-south-1c"

  tags = {
    Name = "Mumbai-subnet-1c"
  }
}

# creating the the ec2 instances

resource "aws_instance" "mumbai-instance" {
  ami           = "ami-026576dd556f3a732"
  instance_type = var.mumbai_instance_type
  key_name = aws_key_pair.mumbai-key-pair.id
  subnet_id = aws_subnet.mumbai-subnet-1a.id
  associate_public_ip_address = "true"
  vpc_security_group_ids = [aws_security_group.Mumbai_SG_allow_ssh_http.id]

  tags = {
    Name = "Mumbai-Instance"
  }
}

resource "aws_instance" "mumbai-instance-2" {
  ami           = "ami-026576dd556f3a732"
  instance_type = "t2.micro"
  key_name = aws_key_pair.mumbai-key-pair.id
  subnet_id = aws_subnet.mumbai-subnet-1a.id
  associate_public_ip_address = "true"
  vpc_security_group_ids = [aws_security_group.Mumbai_SG_allow_ssh_http.id]

  tags = {
    Name = "Mumbai-Instance-2"
  }
}

#creating key pair

resource "aws_key_pair" "mumbai-key-pair" {
  key_name   = "mumbai-23th-june"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBf/btgBbMAXe21xy/fUfk1sYAgxwnqW9LxJ3NSItyPxwrQhvGVSajtZf+hEMoEtWf4Lq/UIslEkrzIki6xzJLYfUJqUr41Xxag5g6W4XqrWxBRrcb15pM2CYRt8Myo1SZeriW1i/5/Wj90vs2FeIH/jGiO2D9pc6nYwfxzVepnD87/5wL+bxPswhU6PvpuiNpNMNYI7J8+UCFnyG1DirhBzdMIQ66gg2eY6fWNDDyEuOzKg201Hvl9ssc4+xrepBGwUyV3ryDwWsLLfuFpBvTY2K6kVrtfMoBZl8/yhjn8ePlAs/bPwm1QeZXYQvFDw+Q3RiJw3BYdPw2sswPxPWt8OXIw0/3yNdK72V7ge76A14cgc/Cf5zPxb23T6hUgpHs18IKRwpaBwx4k/TcLRSasv5iVY3xhc6qlSq1iux2xNi6t+PCY4tzCYPPnCjFZk0EF8xJpgICESQ+SJ3lCCu18sRNYB+39m6S5xLpK1qYb87cXz92kkWR3pR5e4F/7Ws= Amol@DESKTOP-2MVQBON"
  }

  # creating the security group

  resource "aws_security_group" "Mumbai_SG_allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.mumbai-vpc.id

  ingress {
    description      = "SSH from PC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP from PC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "allow_ssh_http"
  }
}

# crating Internet Gateway

resource "aws_internet_gateway" "mumbai_IG" {
  vpc_id = aws_vpc.mumbai-vpc.id

  tags = {
    Name = "Mumbai-IG"
  }
}


#creating the RT

resource "aws_route_table" "mumbai-RT" {
  vpc_id = aws_vpc.mumbai-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mumbai_IG.id
  }


  tags = {
    Name = "mumbai-RT"
  }
}


resource "aws_route_table_association" "mumbai-RT-associaciation-1" {
  subnet_id      = aws_subnet.mumbai-subnet-1a.id
  route_table_id = aws_route_table.mumbai-RT.id
}


resource "aws_route_table_association" "mumbai-RT-associaciation-2" {
  subnet_id      = aws_subnet.mumbai-subnet-1b.id
  route_table_id = aws_route_table.mumbai-RT.id
}

# creating target group

resource "aws_lb_target_group" "mumbai-TG" {
  name     = "cardwebsite-terraform"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.mumbai-vpc.id
}

resource "aws_lb_target_group_attachment" "mumbai-TG-attachment-1" {
  target_group_arn = aws_lb_target_group.mumbai-TG.arn
  target_id        = aws_instance.mumbai-instance.id
  port             = 80
}


resource "aws_lb_target_group_attachment" "mumbai-TG-attachment-2" {
  target_group_arn = aws_lb_target_group.mumbai-TG.arn
  target_id        = aws_instance.mumbai-instance-2.id
  port             = 80
}


resource "aws_lb_listener" "mumbai-listener" {
  load_balancer_arn = aws_lb.mumbai-LB.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mumbai-TG.arn
  }
}

resource "aws_lb" "mumbai-LB" {
  name               = "cardwebsite-LB-Terraform"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Mumbai_SG_allow_ssh_http.id]
  subnets            = [aws_subnet.mumbai-subnet-1b.id, aws_subnet.mumbai-subnet-1a.id]

  
  tags = {
    Environment = "prod"
  }
}

# creating launch template
resource "aws_launch_template" "mumbai-RT" {
  name = "Mumbai-RT"

  image_id = "ami-0f5ee92e2d63afc18"
 
  instance_type = "t2.micro"

  key_name = aws_key_pair.mumbai-key-pair.id


  monitoring {
    enabled = true
  }


  placement {
    availability_zone = "us-west-2a"
  }

  vpc_security_group_ids = [aws_security_group.Mumbai_SG_allow_ssh_http.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Mumbai-instance-ASG"
    }
  }

  user_data = filebase64("userdata.sh")
}

resource "aws_autoscaling_group" "mumbai-ASG" {
  vpc_zone_identifier = [aws_subnet.mumbai-subnet-1a.id, aws_subnet.mumbai-subnet-1b.id]
  
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2

  
  launch_template {
    id      = aws_launch_template.mumbai-RT.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.mumbai-TG-1.arn]
}

# ALB TG with ASG

resource "aws_lb_target_group" "mumbai-TG-1" {
  name     = "Mumbai-TG-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.mumbai-vpc.id
}

# LB Listener with ASG

resource "aws_lb_listener" "mumbai-listener-1" {
  load_balancer_arn = aws_lb.mumbai-LB-1.arn
  port              = "80"
  protocol          = "HTTP"
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mumbai-TG-1.arn
  }
}


#load balancer with ASG

resource "aws_lb" "mumbai-LB-1" {
  name               = "Mumbai-LB-1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Mumbai_SG_allow_ssh_http.id]
  subnets            = [aws_subnet.mumbai-subnet-1b.id, aws_subnet.mumbai-subnet-1a.id]


  tags = {
    Environment = "production"
  }
}