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


# Create public subnet 1
resource "aws_subnet" "status_page_public_subnet1" {
  vpc_id            = aws_vpc.status_page_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name        = "status_page_public_subnet1"
    Description = "This is a public subnet 1 for bastion 1"
  }
}

# Associate public subnet 1 with the route table
resource "aws_route_table_association" "public_subnet_assoc1" {
  subnet_id      = aws_subnet.status_page_public_subnet1.id
  route_table_id = aws_route_table.status_page_route_table_igw.id
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

# Associate public subnet 2 with the route table
resource "aws_route_table_association" "public_subnet_assoc2" {
  subnet_id      = aws_subnet.status_page_public_subnet2.id
  route_table_id = aws_route_table.status_page_route_table_igw.id
}


# Create private subnet 1
resource "aws_subnet" "status_page_private_subnet1" {
  vpc_id            = aws_vpc.status_page_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "status_page_private_subnet1"
  }
}

# Associate the private route table with the private subnet
resource "aws_route_table_association" "status_page_route_table_nat" {
  route_table_id = aws_route_table.status_page_route_table_igw.id
  subnet_id      = aws_subnet.status_page_private_subnet1.id
}


# Create private subnet 2
resource "aws_subnet" "status_page_private_subnet2" {
  vpc_id            = aws_vpc.status_page_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "status_page_private_subnet2"
  }
}

# Associate the private route table with the private subnet
resource "aws_route_table_association" "status_page_private_association2" {
  route_table_id = aws_route_table.status_page_route_table_nat.id
  subnet_id      = aws_subnet.status_page_private_subnet2.id
}


# Create a route table for the private subnet
resource "aws_route_table" "status_page_route_table_nat" {
  vpc_id = aws_vpc.status_page_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.status_page_nat_gateway.id
  }

  tags = {
    Name = "Private Route Table for nat in status page"
  }
}


# Create route table routed to IGW for public subnets 1 and 2
resource "aws_route_table" "status_page_route_table_igw" {
  vpc_id = aws_vpc.status_page_vpc.id

  route {
    cidr_block = "10.1.0.0/16"
    gateway_id = aws_internet_gateway.status_page_igw.id
  }

  tags = {
    Name        = "status_page_route_table_igw"
    Description = "status page route table igw"
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


# Create the NAT gateway
resource "aws_nat_gateway" "status_page_nat_gateway" {
  allocation_id = aws_eip.EIP_NAT.id
  subnet_id     = aws_subnet.status_page_public_subnet1.id

  tags = {
    Name        = "status-page-nat-gateway"
    Description = "status-page-nat-gateway"
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



# create a bastion1
resource "aws_instance" "status_page_bastion1" {
  ami                    = "ami-0f3c9c466bb525749"
  instance_type          = "t2.micro"
  key_name               = "key_bar_ron"
  subnet_id              = aws_subnet.status_page_public_subnet1.id
  vpc_security_group_ids = [aws_security_group.bastion1_security_group.id]

  tags = {
    Name = "status_page_bastion1"
  }
}


# create bastion1 security group1
resource "aws_security_group" "bastion1_security_group" {
  name        = "bastion1_security_group"
  description = "Allow SSH access to bastion1 from my local pc"
  vpc_id      = aws_vpc.status_page_vpc.id


  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
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


# create a bastion2
resource "aws_instance" "status_page_bastion2" {
  ami                    = "ami-0f3c9c466bb525749"
  instance_type          = "t2.micro"
  key_name               = "key_bar_ron"
  subnet_id              = aws_subnet.status_page_public_subnet2.id
  vpc_security_group_ids = [aws_security_group.bastion2_security_group.id]

  tags = {
    Name = "status_page_bastion2"
  }
} 


# create bastion2 security group
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


resource "aws_security_group" "production_security_group" {
  name = "production_security_group"
  description = "Allow SSH access to production1 from bastion security groups"
  vpc_id = aws_vpc.status_page_vpc.id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion1_security_group.id]
  }


    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion2_security_group.id]
  }


  tags = {
    Name = "production_security_group"
    Description = "Allow SSH access to production1 from bastion security groups"
  }
}


# create a sg to elb 
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  vpc_id      = aws_vpc.status_page_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "alb_sg"
  }
}


# create LB for the prodaction
resource "aws_lb" "status_page_elb" {
  name               = "StatusPageELB"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.status_page_private_subnet1.id, aws_subnet.status_page_private_subnet2.id]

  tags = {
    Name = "status_page_elb"
  }
}

resource "aws_lb_listener" "stastus_page_lb_listener" {
  load_balancer_arn = aws_lb.status_page_elb.arn
  port              = "80"
  protocol          = "HTTP"
#  ssl_policy        = "ELBSecurityPolicy-2016-08" -----
#  certificate_arn   = "arn:aws:acm:us-west-2:123456789012:certificate/abcd1234-5678-90ef-ghij-klmn1234abcd" ------

  default_action {
    target_group_arn = aws_lb_target_group.status_page_lb_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "status_page_lb_target_group" {
  name     = "StatusPageLBtargetGroup"
  port              = "80"
  protocol          = "HTTP"
  vpc_id   = aws_vpc.status_page_vpc.id

  health_check {
    enabled = true
    interval = 30
    timeout = 5
    protocol = "HTTPS"
    port     = 80
    path = "/"
    matcher = "200-399" 
  }

  stickiness {
    type         = "lb_cookie"
    cookie_duration = 600
    cookie_name      = "sticky-cookie"
  }
}

 
# create a ECS cluster that deploys two EC2 instances  
resource "aws_ecs_cluster" "status_page_ecs" {
  name = "status_page_ecs"
}

resource "aws_ecs_task_definition" "status_page_task" {
  family                   = "status_page_task"
  container_definitions    =  <<DEFINITION
[
  {
    "name": "status_page_app",
    "image": "017697353720.dkr.ecr.ap-southeast-1.amazonaws.com/status-page-baron:1", 
    "cpu": 256,
    "memory": 512,
    "portMappings": [
      {
        "containerPort": 8000,
        "hostPort": 8000
      }
    ],
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

   /* network_configuration {
    awsvpc_configuration {
      subnets         = [aws_subnet.status_page_private_subnet1.id, aws_subnet.status_page_private_subnet2.id]
      security_groups = [aws_security_group.production_security_group.id]
    }
  } */

  load_balancer {
    target_group_arn = aws_lb_target_group.status_page_lb_target_group.arn
    container_name   = "status_page_app"
    container_port   = 8000
  }
}    

/* 
?
placement_constraints {
    type       = "distinctInstance"
    expression = "attribute:ecs.availability-zone"
  }

service_registries {
    registry_arn = aws_service_discovery_private_dns_namespace.my_namespace.arn
  }

autoscaling {
    min_capacity = 1
    max_capacity = 10
  }

#create ASG TO THE PROUD AND TO BASRION  */




/* # create a WAF rules
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

*/ 
