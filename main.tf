# Configure the AWS Provider
provider "aws" {
  
}

variable "cidr-blocks" {
  
}

variable "subnet-cidr-blocks" {
  
}

variable "avail_zone" {
}

variable "env_prefix" {
  
}

variable "my_ip" {
  
}
variable "aws_instance_type" {
  
}
variable "ssh-key-pair" {
  
}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.cidr-blocks
  tags = {
    Name = "${var.env_prefix}-vpc"
    
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id     = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet-cidr-blocks
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet"
  }
}

resource "aws_route_table" "myapp-route_table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igx.id
  }
  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}

resource "aws_internet_gateway" "myapp-igx" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name = "${var.env_prefix}-igx"
  }
}

resource "aws_route_table_association" "myapp-rtb_association" {
  subnet_id = aws_subnet.myapp-subnet-1.id 
  route_table_id = aws_route_table.myapp-route_table.id
}

resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id
  ingress {
    description = "SSH into EC2"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
   ingress {
    description = "traffic to webserver"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "traffic from webserver"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "outgoing from instance to ec2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name = "${var.env_prefix}-sg"
  }
}

data "aws_ami" "latest_ami" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "ami_id" {
  value = data.aws_ami.latest_ami.id
  
}
resource "aws_key_pair" "key-pair" {
  key_name   = "ssh-keys"
  public_key = file(var.ssh-key-pair)
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest_ami.id 
  instance_type = var.aws_instance_type
  subnet_id = aws_subnet.myapp-subnet-1.id 
  vpc_security_group_ids = [aws_security_group.myapp-sg.id] 
  availability_zone = var.avail_zone
  associate_public_ip_address = true
  key_name = aws_key_pair.key-pair.key_name
  user_data = file("entryscript.sh")

  tags = {
    "Name" = "${var.env_prefix}-server"
  }

  
  
}
  

