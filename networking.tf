# ==============================================================================
# TEN-Agent ECS Deployment - Networking Resources
# ==============================================================================
# This file defines VPC, subnets, route tables, NAT gateways, and security groups

# ==============================================================================
# VPC
# ==============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc"
    }
  )
}

# ==============================================================================
# Internet Gateway
# ==============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-igw"
    }
  )
}

# ==============================================================================
# Public Subnets
# ==============================================================================

resource "aws_subnet" "public" {
  count = var.availability_zones_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-subnet-${count.index + 1}"
      Type = "Public"
    }
  )
}

# ==============================================================================
# Private Subnets
# ==============================================================================

resource "aws_subnet" "private" {
  count = var.availability_zones_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 100)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-subnet-${count.index + 1}"
      Type = "Private"
    }
  )
}

# ==============================================================================
# Elastic IPs for NAT Gateways
# ==============================================================================

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : var.availability_zones_count) : 0

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ==============================================================================
# NAT Gateways
# ==============================================================================

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : var.availability_zones_count) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-gateway-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ==============================================================================
# Route Table for Public Subnets
# ==============================================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-rt"
    }
  )
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count = var.availability_zones_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ==============================================================================
# Route Tables for Private Subnets
# ==============================================================================

resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? var.availability_zones_count : 1

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-rt-${count.index + 1}"
    }
  )
}

resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? var.availability_zones_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private" {
  count = var.availability_zones_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.enable_nat_gateway ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}

# ==============================================================================
# Security Group for ALB
# ==============================================================================

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP traffic"
  
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS traffic"
  
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_agents_port" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow traffic to agents service"
  
  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_playground_port" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow traffic to playground service"
  
  from_port   = 3000
  to_port     = 3000
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_nova_sonic_port" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow traffic to nova sonic service"
  
  from_port   = 3333
  to_port     = 3333
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_graph_designer_port" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow traffic to graph designer internal port"
  
  from_port   = 49483
  to_port     = 49483
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"
  
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ==============================================================================
# Security Group for ECS Tasks
# ==============================================================================

resource "aws_security_group" "ecs_tasks" {
  name        = "${local.name_prefix}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ecs-tasks-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow traffic from ALB"
  
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_inter_service" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow inter-service communication"
  
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_tasks.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_all" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow all outbound traffic"
  
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ==============================================================================
# VPC Endpoints (Optional - for private subnet access to AWS services)
# ==============================================================================

# Uncomment below to create VPC endpoints for AWS services
# This allows private subnet resources to access AWS services without NAT Gateway

# resource "aws_vpc_endpoint" "ecr_api" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
#
#   tags = merge(
#     local.common_tags,
#     {
#       Name = "${local.name_prefix}-ecr-api-endpoint"
#     }
#   )
# }
#
# resource "aws_vpc_endpoint" "ecr_dkr" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
#
#   tags = merge(
#     local.common_tags,
#     {
#       Name = "${local.name_prefix}-ecr-dkr-endpoint"
#     }
#   )
# }
#
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.aws_region}.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = aws_route_table.private[*].id
#
#   tags = merge(
#     local.common_tags,
#     {
#       Name = "${local.name_prefix}-s3-endpoint"
#     }
#   )
# }
#
# resource "aws_security_group" "vpc_endpoints" {
#   name        = "${local.name_prefix}-vpc-endpoints-sg"
#   description = "Security group for VPC endpoints"
#   vpc_id      = aws_vpc.main.id
#
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [var.vpc_cidr]
#   }
#
#   tags = merge(
#     local.common_tags,
#     {
#       Name = "${local.name_prefix}-vpc-endpoints-sg"
#     }
#   )
# }
