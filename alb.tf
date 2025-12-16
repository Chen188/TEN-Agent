# ==============================================================================
# TEN-Agent ECS Deployment - Application Load Balancer
# ==============================================================================
# This file defines ALB, target groups, and listeners

# ==============================================================================
# Application Load Balancer
# ==============================================================================

resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = true
  idle_timeout              = var.alb_idle_timeout

  dynamic "access_logs" {
    for_each = var.enable_alb_access_logs ? [1] : []
    content {
      bucket  = var.alb_access_logs_bucket
      enabled = true
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb"
    }
  )
}

# ==============================================================================
# Target Groups
# ==============================================================================

# Target Group - Agents Service (Port 8080)
resource "aws_lb_target_group" "agents" {
  name        = "${local.name_prefix}-agents-tg"
  port        = var.server_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path["agents"]
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-agents-tg"
    }
  )
}

# Target Group - Graph Designer Internal (Port 49483)
resource "aws_lb_target_group" "graph_designer" {
  name        = "${local.name_prefix}-graph-designer-tg"
  port        = var.graph_designer_server_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-graph-designer-tg"
    }
  )
}

# Target Group - Playground Service (Port 3000)
resource "aws_lb_target_group" "playground" {
  name        = "${local.name_prefix}-playground-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path["playground"]
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-playground-tg"
    }
  )
}

# Target Group - Nova Sonic Service (Port 3333)
resource "aws_lb_target_group" "nova_sonic" {
  name        = "${local.name_prefix}-nova-sonic-tg"
  port        = 3333
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path["nova_sonic"]
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nova-sonic-tg"
    }
  )
}

# ==============================================================================
# HTTP Listeners (Port-based routing)
# ==============================================================================

# Listener - Agents Service (Port 8080)
resource "aws_lb_listener" "agents" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.server_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.agents.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-agents-listener"
    }
  )
}

# Listener - Graph Designer (Port 49483)
resource "aws_lb_listener" "graph_designer" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.graph_designer_server_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graph_designer.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-graph-designer-listener"
    }
  )
}

# Listener - Playground Service (Port 3000)
resource "aws_lb_listener" "playground" {
  load_balancer_arn = aws_lb.main.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.playground.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-playground-listener"
    }
  )
}

# Listener - Nova Sonic Service (Port 3333)
resource "aws_lb_listener" "nova_sonic" {
  load_balancer_arn = aws_lb.main.arn
  port              = 3333
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nova_sonic.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nova-sonic-listener"
    }
  )
}

# ==============================================================================
# HTTPS Listeners (Domain-based routing - enabled when custom domain is set)
# ==============================================================================

# Listener - HTTPS (Port 443) with SSL certificate
resource "aws_lb_listener" "https" {
  count = var.enable_custom_domain ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main[0].arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service not found"
      status_code  = "404"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-https-listener"
    }
  )

  depends_on = [aws_acm_certificate_validation.main]
}

# Listener Rule - Route to Agents based on subdomain
resource "aws_lb_listener_rule" "agents_https" {
  count = var.enable_custom_domain ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.agents.arn
  }

  condition {
    host_header {
      values = ["${var.subdomain_agents}.${var.domain_name}"]
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-agents-https-rule"
    }
  )
}

# Listener Rule - Route to Playground based on subdomain
resource "aws_lb_listener_rule" "playground_https" {
  count = var.enable_custom_domain ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.playground.arn
  }

  condition {
    host_header {
      values = ["${var.subdomain_playground}.${var.domain_name}"]
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-playground-https-rule"
    }
  )
}

# Listener Rule - Route to Nova Sonic based on subdomain
resource "aws_lb_listener_rule" "nova_sonic_https" {
  count = var.enable_custom_domain ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nova_sonic.arn
  }

  condition {
    host_header {
      values = ["${var.subdomain_nova_sonic}.${var.domain_name}"]
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nova-sonic-https-rule"
    }
  )
}

# Listener - HTTP (Port 80) - Redirect to HTTPS when custom domain is enabled
resource "aws_lb_listener" "http_redirect" {
  count = var.enable_custom_domain ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-http-redirect-listener"
    }
  )
}
