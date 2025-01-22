# Terraform script to create an MSK Kafka cluster and an IAM role

provider "aws" {
  region = "us-east-1" # Change the region as needed
}

# Create IAM Role
resource "aws_iam_role" "msk_access_role" {
  name = "msk-access-role"
  assume_role_policy = <<EOF
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
}
EOF
}

# Attach policy to the IAM Role
resource "aws_iam_role_policy" "msk_access_policy" {
  name   = "msk-access-policy"
  role   = aws_iam_role.msk_access_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kafka:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Create a VPC
resource "aws_vpc" "msk_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create subnets
resource "aws_subnet" "msk_subnet" {
  count             = 3
  vpc_id            = aws_vpc.msk_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.msk_vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# Fetch available availability zones
data "aws_availability_zones" "available" {}

# Security group for MSK
resource "aws_security_group" "msk_sg" {
  name   = "msk-security-group"
  vpc_id = aws_vpc.msk_vpc.id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create MSK cluster
resource "aws_msk_cluster" "example" {
  cluster_name           = "example-msk-cluster"
  kafka_version          = "3.4.0" # Change as needed
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = "kafka.m5.large"
    client_subnets  = aws_subnet.msk_subnet[*].id
    security_groups = [aws_security_group.msk_sg.id]
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled = true
        log_group = aws_cloudwatch_log_group.msk_log_group.name
      }
    }
  }
}

# CloudWatch log group for MSK
resource "aws_cloudwatch_log_group" "msk_log_group" {
  name              = "/aws/msk/example-cluster"
  retention_in_days = 7
}
