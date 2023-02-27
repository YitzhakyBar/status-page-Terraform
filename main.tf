# specify the required version and provider for AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}


# # specify the required version and provider for GCP
# terraform {
#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = "~> 3.0"
#     }
#   }
#   required_version = ">= 1.1.0"
# }


# # Define GCP as provider
# provider "google" {
#   credentials = file("path/to/your/gcp_credentials.json")
#   project     = "your_gcp_project_id"
#   region      = "your_gcp_region"
# }

# Define AWS as provider
provider "aws" {
  region = "us-east-2"
}


# Create VPC
resource "aws_vpc" "status_page_vpc" {
  cidr_block = "10.0.0.0/16"


  tags = {
    Name        = "status_page_vpc"
    Description = "This is a VPC for status_page infrastructure"
  }
}

# Create internet gateway for public subnet
resource "aws_internet_gateway" "status_page_igw" {
  vpc_id = aws_vpc.status_page_vpc.id

  tags = {
    Name        = "status_page_IGW"
    Description = "This is a IGW for the public subnets"
  }
}


# Create route table routed to IGW for public subnets 1 and 2
resource "aws_route_table" "status_page_route_table_igw" {
  vpc_id = aws_vpc.status_page_vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.status_page_igw.id

  }
  tags = {
    Name        = "status_page_route_table_igw"
    Description = "status page route table igw"
  }
}

# create an EIP for NAT gateway
resource "aws_eip" "EIP_NAT" {
  vpc = true

  tags = {
    Name = "EIP-for-NAT"
    Description = "EIP assigned to NAT gateway"
  }
}

# Create the NAT gateway
resource "aws_nat_gateway" "status_page_nat_gateway" {
  allocation_id = aws_eip.EIP_NAT.id
  subnet_id = aws_subnet.status_page_public_subnet1.id
  tags = {
    Name = "status-page-nat-gateway"
    Description = "status-page-nat-gateway"
  }
}

# Create a route table for the private subnet
resource "aws_route_table" "private_subnet_route_table" {
  vpc_id = aws_vpc.status_page_vpc.id


  route {
    cidr_block     = "10.0.1.0/24"
    nat_gateway_id = aws_nat_gateway.status_page_nat_gateway.id
  }


  tags = {
    Name = "Private Route Table for nat in status page"
  }
}


# Associate the private route table with the private subnet
resource "aws_route_table_association" "status_page_private_association" {
  route_table_id = aws_route_table.private_subnet_route_table.id
  subnet_id = aws_subnet.status_page_private_subnet1.id
}


# Create public subnet 1
resource "aws_subnet" "status_page_public_subnet1" {
  vpc_id            = aws_vpc.status_page_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"


  tags = {
    Name        = "status_page_public_subnet1"
    Description = "This is a public subnet 1 for bastion 1"
  }
}


# Create public subnet 2
resource "aws_subnet" "status_page_public_subnet2" {
  vpc_id            = aws_vpc.status_page_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"


  tags = {
    Name        = "status_page_public_subnet2"
    Description = "This is a public subnet 2 for bastion 2"
  }
}


# Associate public subnet 1 with the route table
resource "aws_route_table_association" "public_subnet1_assoc" {
  subnet_id      = aws_subnet.status_page_public_subnet1.id
  route_table_id = aws_route_table.status_page_route_table_igw.id
}


# Associate public subnet 2 with the route table
resource "aws_route_table_association" "public_subnet2_assoc" {
  subnet_id      = aws_subnet.status_page_public_subnet2.id
  route_table_id = aws_route_table.status_page_route_table_igw.id
}


# Create private subnet 1
resource "aws_subnet" "status_page_private_subnet1" {
  vpc_id            = aws_vpc.status_page_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"
}


# Create private subnet 2
resource "aws_subnet" "status_page_private_subnet2" {
  vpc_id            = aws_vpc.status_page_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"
}


# Create a route table for the private subnet
resource "aws_route_table" "status_page_private_subnet_route_table" {
  vpc_id = aws_vpc.status_page_vpc.id

  route {
    cidr_block     = "10.0.1.0/24"
    nat_gateway_id = aws_nat_gateway.status_page_nat_gateway.id
  }

  tags = {
    Name = "Private Route Table for nat in status page"
  }
}
/*
resource "aws_security_group" "bastion1_security_group" {
  name        = "bastion1_security_group"
  description = "Allow SSH access to bastion1 from my local pc"
  vpc_id      = aws_vpc.status_page_vpc.id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["77.125.2.122/32", "77.137.65.124/32"]
  }


  tags = {
    Name        = "bastion1_security_group"
    Description = "security group for 1st bastion"
  }
}


resource "aws_security_group" "bastion2_security_group" {
  name        = "bastion2_security_group"
  description = "Allow SSH access to bastion2 from my local pc"
  vpc_id      = aws_vpc.status_page_vpc.id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["77.125.2.122/32", "77.137.65.124/32"]
  }


  tags = {
    Name        = "bastion2_security_group"
    Description = "security group for 2nd bastion"
  }
}


resource "aws_security_group" "production1_security_group" {
  name        = "production1_security_group"
  description = "Allow SSH access to production1 from bastion security groups"
  vpc_id      = aws_vpc.status_page_vpc.id

  ingress {
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.bastion2_security_group.id
  }


  tags = {
    Name        = "production1_security_group"
    Description = "Allow SSH access to production1 from bastion security groups"
  }
} */
