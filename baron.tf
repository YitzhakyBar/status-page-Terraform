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
  region = "ap-southeast-1"
}


# Create VPC
resource "aws_vpc" "status_page_vpc" {

  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "status_page_vpc"
    Description = "This is a VPC for status_page infrastructure"
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

# Create private subnet 1
resource "aws_subnet" "status_page_private_subnet1" {
  vpc_id            = aws_vpc.status_page_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "status_page_private_subnet1"
  }
}

# Associate the private route table with the private subnet
resource "aws_route_table_association" "status_page_route_table_nat" {
  route_table_id = aws_route_table.status_page_route_table_nat.id
  subnet_id      = aws_subnet.status_page_private_subnet1.id
}

# Create private subnet 2
resource "aws_subnet" "status_page_private_subnet2" {
  vpc_id            = aws_vpc.status_page_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "status_page_private_subnet2"
  }
}

# Associate the private route table with the private subnet
resource "aws_route_table_association" "status_page_private_association2" {
  route_table_id = aws_route_table.status_page_route_table_nat.id
  subnet_id      = aws_subnet.status_page_private_subnet2.id
}

# Create public subnet 1
resource "aws_subnet" "status_page_public_subnet1" {
  vpc_id            = aws_vpc.status_page_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"

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
  availability_zone = "ap-southeast-1b"

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



# create a bastion1
resource "aws_instance" "status_page_bastion1" {
  ami                    = "ami-03f6a11788f8e319e" #amazon linux 2
  instance_type          = "t2.micro"
  key_name               = "key_bar_ron"
  subnet_id              = aws_subnet.status_page_public_subnet1.id
  vpc_security_group_ids = [aws_security_group.bastion1_security_group.id]
  associate_public_ip_address = true
  tags = {
    Name = "bastion1_status_page"
  }
}


# create bastion1 security group1
resource "aws_security_group" "bastion1_security_group" {
  name        = "bastion1_security_group"
  description = "Allow SSH access to bastion1 from my local pc"
  vpc_id      = aws_vpc.status_page_vpc.id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "bastion1_security_group"
    Description = "security group for 1st bastion"
  }
}


# create a bastion2
resource "aws_instance" "status_page_bastion2" {
  ami                    = "ami-03f6a11788f8e319e" #amazon linux 2
  instance_type          = "t2.micro"
  key_name               = "key_bar_ron"
  subnet_id              = aws_subnet.status_page_public_subnet2.id
  vpc_security_group_ids = [aws_security_group.bastion2_security_group.id]
  associate_public_ip_address = true
  tags = {
    Name = "bastion2_status_page"
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
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "bastion2_security_group"
    Description = "security group for 2nd bastion"
  }
}

# create production security group
resource "aws_security_group" "production_security_group" {
  name        = "production_security_group"
  description = "Allow SSH access to production1 from bastion security groups"
  vpc_id      = aws_vpc.status_page_vpc.id


  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion1_security_group.id]
  }


  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion2_security_group.id]
  }

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "production_security_group"
    Description = "Allow SSH access to production1 from bastion security groups"
  }
}


# create a sg to elb 
resource "aws_security_group" "alb_sg" {
  name   = "alb_sg"
  vpc_id = aws_vpc.status_page_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_sg"
  }
}

#_____________________________________________________________________________________________________________________________

# create LB for the production
resource "aws_lb" "status_page_elb" {
  name               = "StatusPageELB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.status_page_public_subnet1.id, aws_subnet.status_page_public_subnet2.id]
  tags = {
    Name = "status_page_elb"
  }
}

resource "aws_lb_listener" "stastus_page_lb_listener" {
  load_balancer_arn = aws_lb.status_page_elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group_lb_status_page.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "target_group_lb_status_page" {
  name     = "LB-targetGroup"
  port     = "8000"
  protocol = "HTTP"
  vpc_id   = aws_vpc.status_page_vpc.id
  deregistration_delay = 30
  
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    path                = "/"
    matcher             = "200"
  }
}

#_________________________________________________________________________________________________________________________
# create autoscaling group and launch tenplate for production
resource "aws_launch_template" "status_page_launch_template" {
  iam_instance_profile {
    name = "ecs_agent"
  }
  name_prefix   = "status_page_launch_template"
  image_id      = "ami-0e9a0ac4214f2ebe1" # ECS-Optimized Amazon Linux 2 AMI ID
  instance_type = "t3.small"
  key_name      = "key_bar_ron"
  user_data     = filebase64("/home/ubuntu/new-test/user_data.sh")
  vpc_security_group_ids = [aws_security_group.production_security_group.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Production"
    }
  }
}

resource "aws_autoscaling_group" "prod_autoscaling_group" {
  name_prefix = "prod_autoscaling_group"
  launch_template {
  id      = aws_launch_template.status_page_launch_template.id
  version = "$Latest"
  }
  min_size                  = 2
  max_size                  = 4
  health_check_grace_period = 300
  health_check_type         = "EC2"
  target_group_arns     = [aws_lb_target_group.target_group_lb_status_page.arn]
  vpc_zone_identifier   = [aws_subnet.status_page_private_subnet1.id]
  tag {
    key         = "prod_autoscaling_group"
    value       = "ASG for production"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.prod_autoscaling_group.id
  lb_target_group_arn    = aws_lb_target_group.target_group_lb_status_page.arn
}

#_____________________________________________________________________________________________________

# Create a ECS cluster that deploys two tasks on the production EC2 instances  
# Create a security group for tasks
resource "aws_security_group" "ecs_task_sg" {
  name_prefix = "example-security-group"
  vpc_id      = aws_vpc.status_page_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "status_page_ecs" {
  name = "status_page_ecs"
}

# Create an ecs service
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.status_page_ecs.id
  task_definition = aws_ecs_task_definition.status_page_task.arn
  desired_count   = 1
  launch_type     = "EC2"
  load_balancer {
    target_group_arn = aws_lb_target_group.target_group_lb_status_page.arn
    container_name   = "status_page_container"
    container_port   = 8000
  }
}


resource "aws_ecs_task_definition" "status_page_task" {
  family         = "status_page_task"
  task_role_arn  = aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions = jsonencode(
    [
      {
        name      = "status_page_container",
        cpu       = 1,
        memory    = 512,
        essential = true,
        image     = "017697353720.dkr.ecr.ap-southeast-1.amazonaws.com/status-page-baron:3",
        # "environment": [],
        portMappings = [
          {
            containerPort = 8000,
            hostPort = 8000,
            protocol = "tcp"
          }
        ]
          
      }
    ]
  )
}
#_________________________________________________________________________________

# Create rds security group
resource "aws_security_group" "rds_sg" {
  name        = "rds_security_group"
  description = "Open port 5432 for production"
  vpc_id      = aws_vpc.status_page_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.production_security_group.id]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "rds_subnet_group"
  description = "Subnet group for RDS"
  subnet_ids = [
    aws_subnet.status_page_private_subnet1.id,
    aws_subnet.status_page_private_subnet2.id,
  ]
  tags = {
    Name = "rds-subnet-group"
  }
}


resource "aws_db_instance" "rds_instance" {
  engine                  = "postgres"
  engine_version          = "14.6"
  identifier              = "database-1"
  username                = "statuspage"
  password                = "statuspage1"
  instance_class          = "db.t3.small"
  storage_type            = "gp2"
  allocated_storage       = 100
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = false
  multi_az                = true
  db_name                    = "statuspage" # set the initial database name here
  parameter_group_name    = "default.postgres14"
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
}

#____________________________________________________________________
#REDIS
# redis security group
resource "aws_security_group" "redis_sg" {
  name   = "example-redis"
  description = "Open port 6379 for production"
  vpc_id = aws_vpc.status_page_vpc.id

  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_groups = [aws_security_group.production_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
#Create elasticache subnet group
resource "aws_elasticache_subnet_group" "elasticache_subnet_group" {
  name       = "elasticache-subnet-group"
  subnet_ids = [
    aws_subnet.status_page_private_subnet1.id,
    aws_subnet.status_page_private_subnet2.id,
  ]
  tags = {
    Name = "elasticache-subnet-group"
  }
}

# Create elasticache cluster

resource "aws_elasticache_cluster" "elasticache_cluster" {
  cluster_id           = "status-page-cluster"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  subnet_group_name    = aws_elasticache_subnet_group.elasticache_subnet_group.name
  parameter_group_name = "default.redis7"
  port                 = 6379
  security_group_ids = [aws_security_group.redis_sg.id]
}
