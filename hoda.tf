# establish the provider 

provider "aws" {
    region = "us-east-1"
}

# creating vpc 

resource "aws_vpc" "SALAHDIN_vpc" {               
   cidr_block       = "10.0.0.0/16"    
   instance_tenancy = "default"
   tags = {
      Name = "salahdin_vpc"
   }
}

# creating puplic 2 subnet 

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.SALAHDIN_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public Subnet"
  }
}


resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.SALAHDIN_vpc.id
  cidr_block = "10.0.30.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public Subnet"
  }
}

# creating puplic 2 privat  subnet 

resource "aws_subnet" "privat1" {
  vpc_id     = aws_vpc.SALAHDIN_vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "privat Subnet 1"
  }
}

resource "aws_subnet" "privat2" {
  vpc_id     = aws_vpc.SALAHDIN_vpc.id
  cidr_block = "10.0.20.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "privat Subnet 1"
  }
}


# creating AWS IGW

resource "aws_internet_gateway" "SALAHDIN_igw" {
  vpc_id = aws_vpc.SALAHDIN_vpc.id

  tags = {
    Name = "SALAHDIN_vpc- Internet Gateway"
  }
}

# creating route table for puplic subnets 

resource "aws_route_table" "SALAHDIN_route_table_public" {
    vpc_id = aws_vpc.SALAHDIN_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.SALAHDIN_igw.id
    }

    tags = {
        Name = "Public Subnet Route Table."
    }
}

# creating and associate the route table with puplic subnet 

resource "aws_route_table_association" "SALAHDIN_vpc_us_east_1a_public_aso" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.SALAHDIN_route_table_public.id
}

# creating and associate the route table with privat subnet 

resource "aws_route_table" "SALAHDIN_route_table_privat" {
    vpc_id = aws_vpc.SALAHDIN_vpc.id
    tags = {
        Name = "Public Subnet Route Table."
    }
}

# creating and associate the route table with privat1 subnet 

resource "aws_route_table_association" "SALAHDIN_vpc_us_east_1a_privat1_aso" {
    subnet_id = aws_subnet.privat1.id
    route_table_id = aws_route_table.SALAHDIN_route_table_privat.id
}

# creating and associate the route table with privat2 subnet 

resource "aws_route_table_association" "SALAHDIN_vpc_us_east_1a_privat2_aso" {
    subnet_id = aws_subnet.privat2.id
    route_table_id = aws_route_table.SALAHDIN_route_table_privat.id

}


resource "aws_security_group" "salah-sec-group" {
  name        = "salah-sec-group"
  description = "Allow tls inbound traffic"
  vpc_id      = aws_vpc.SALAHDIN_vpc.id

  ingress {
    description      = "inbound rules from VPC"
    from_port        = 0
    to_port          = 1000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

 egress {
    from_port        = 0
    to_port          = 1000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  tags = {
    Name = "aws_security_group"
    instance_name = "aws_instance"
  }
}
resource "aws_instance" "ec2-instance1" {
    ami = "ami-0c02fb55956c7d316"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.salah-sec-group.id]
    key_name = "SALAHDIN"
    subnet_id = aws_subnet.privat1.id
    user_data =   <<-EOF
                  #!/bin/bash
                  sudo su
                  amazon-linux-extras enable nginx1
                  yum -y install update
                  yum -y install nginx
                  echo "<p> SALAHDIN WEB SERVER TEST LOAD BALANCER 111! </p>" >> /usr/share/nginx/html/index.html
                  sudo systemctl enable nginx
                  sudo systemctl start nginx
                  EOF
}
resource "aws_instance" "ec2-instance2" {
    ami = "ami-0c02fb55956c7d316"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.salah-sec-group.id]
    key_name = "SALAHDIN"
    subnet_id = aws_subnet.privat2.id
    user_data =   <<-EOF
                  #!/bin/bash
                  sudo su
                  amazon-linux-extras enable nginx1
                  yum -y install update
                  yum -y install nginx
                  echo "<p> SALAHDIN WEB SERVER TEST LOAD BALANCER 222! </p>" >> /usr/share/nginx/html/index.html
                  sudo systemctl enable nginx
                  sudo systemctl start nginx
                  EOF
}



resource "aws_lb" "SALAHDIN_ELB" {
  name               = "salahdinlb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public.id, aws_subnet.public2.id]
}
  resource "aws_lb_target_group" "SALAHDIN_TARGET" {
  name     = "salahdin"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.SALAHDIN_vpc.id

}

resource "aws_lb_target_group_attachment" "TARGET_ATTACH1" {
  target_group_arn = aws_lb_target_group.SALAHDIN_TARGET.arn
  target_id        = aws_instance.ec2-instance1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "TARGET_ATTACH2" {
  target_group_arn = aws_lb_target_group.SALAHDIN_TARGET.arn
  target_id        = aws_instance.ec2-instance2.id
  port             = 80
}

resource "aws_lb_listener" "listener_http" {
  load_balancer_arn = aws_lb.SALAHDIN_ELB.arn
  port              = "80"
  protocol          = "HTTP"

default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.SALAHDIN_TARGET.arn
  }

}






terraform {
  backend "s3" {
    bucket         = "salahdin-bucket"
    key            = "Group1/terraform.tfstate"
    region         = "us-east-1"
  }
}



