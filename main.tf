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


# Define AWS as provider
provider "aws" {
  region = "us_east_2"
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
    Name        = "EIP-for-NAT"
    Description = "EIP assigned to NAT gateway"
  }
}

# Create the NAT gateway
resource "aws_nat_gateway" "status_page_nat_gateway" {
  allocation_id = aws_eip.EIP_NAT.id
  subnet_id     = aws_subnet.status_page_public_subnet1.id

  tags = {
    Name        = "status-page-nat-gateway"
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
  subnet_id      = aws_subnet.status_page_private_subnet1.id
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
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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

   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
    from_port                = 8000
    to_port                  = 8000
    protocol                 = "tcp"
    security_groups = ["${aws_security_group.bastion1_sg.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  tags = {
    Name        = "production1_security_group"
    Description = "Allow SSH access to production1 from bastion security groups"
  }
}

resource "aws_security_group" "production2_security_group" {
  name        = "production1_security_group"
  description = "Allow SSH access to production1 from bastion security groups"
  vpc_id      = aws_vpc.status_page_vpc.id

  ingress {
    from_port                = 8000
    to_port                  = 8000
    protocol                 = "tcp"
    cidr_blocks = ["77.125.2.122/32", "77.137.65.124/32"]
    security_groups = ["${aws_security_group.bastion2_sg.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "production2_security_group"
    Description = "Allow SSH access to production1 from bastion security groups"
  }
}






 





# create a WAF rules
variable "waf_rules" {
  type    = list(string)
  default = [
    "AWSManagedRulesCommonRuleSet",
    "AWSManagedRulesAmazonIpReputationList",
    "AWSManagedRulesKnownBadInputsRuleSet",
    "AWSManagedRulesLinuxRuleSet",
    "AWSManagedRulesSQLiRuleSet",
    "AWSManagedRulesWindowsRuleSet",
    "AWSManagedRulesPHPRuleSet"
  ]

   tags = {
    Name        = "status_page_waf_rules"
  }


}
 # create the AWS WAF web ACL
 resource "aws_wafv2_web_acl" "status_+page_WAF" {
  name = var.waf_name

  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name      = "AWSManagedRulesCommonRuleSet"
    priority = 0
    override_action {
      none {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name      = "AWSManagedRulesAmazonIpReputationList"
    priority = 1
    override_action {
      none {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = var.waf_rules
    content {
      name      = rule.value
      priority = index(var.waf_rules, rule.value) + 2
      override_action {
        none {}
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                 = rule.value
        sampled_requests_enabled   = true
      }
    }
  }

  tags = {
    AppName = var.app_name
  }
}








# create ELB for the prodaction
resource "aws_lb" "status_page_elb" {
  name               = "status_page_elb"
  internal           = true
  load_balancer_type = "application"
  subnets            = [aws_subnet.status_page_private_subnet1.id, aws_subnet.status_page_private_subnet2.id]

  security_groups = [
    aws_security_group.production1_security_group.id, aws_security_group.production2_security_group.id,
  ]

  tags = {
    Name = "status_page-lb"
  }
}

resource "aws_lb_listener" "stastus_page_lb_listener" {
  load_balancer_arn = aws_lb.example.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" -----
  certificate_arn   = "arn:aws:acm:us-west-2:123456789012:certificate/abcd1234-5678-90ef-ghij-klmn1234abcd" ------

  default_action {
    target_group_arn = aws_lb_target_group.status_page_lb_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "status_page_lb_target_group" {
  name     = "status_page_lb_target_group"
  port              = "443"
  protocol          = "HTTPS"
  vpc_id   = aws_vpc.status_page_vpc.id

  health_check {
    enabled = true
    interval = 30
    timeout = 5
    protocol = "HTTPS"
    port     = 443
    path = "/"
    matcher = "200-399"
    tls      = true 
  }

  stickiness {
    type         = "lb_cookie"
    cookie_duration = 600
    cookie_name      = "sticky-cookie"
    cookie_secure    = true
    cookie_httponly  = true
  }
}

# create a ECS cluster that deploys two EC2 instances  
resource "aws_ecs_cluster" "status_page_ecs" {
  name = "status_page_ecs"
}

resource "aws_ecs_task_definition" "status_page_task" {
  family                   = "cluster-task"
  container_definitions    = <<DEFINITION
[
  {
    "name": "web",
    "image": "nginx:latest", --- docker image ----
    "portMappings": [
      {
        "containerPort": 8000,
        "hostPort": 8000
      }
    ]
    "environment": [
      {
        "name": "APP_ENV",
        "value": "prod"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "status_page_ec2" {
  name            = "ec2-service"
  cluster         = aws_ecs_cluster.status_page_ecs.id
  task_definition = aws_ecs_task_definition.status_page_task.arn
  desired_count   = 2
  launch_type     = "EC2"

  network_configuration {
    subnet_ids      = [aws_subnet.status_page_private_subnet1.id, aws_subnet.status_page_private_subnet2.id]
    security_groups = [aws_security_group.production1_security_group.id, aws_security_group.production2_security_group.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.status_page_lb_target_group.arn
    container_name   = "web"
    container_port   = 8000
  }
}
 