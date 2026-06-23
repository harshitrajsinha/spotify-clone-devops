# ACM for custom domain
resource "aws_acm_certificate" "spotify_domain_certificate" {
  domain_name               = var.my_domain_name
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.my_domain_name}"]

  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "acm_domain_options" {
  value = aws_acm_certificate.spotify_domain_certificate.domain_validation_options
}

# ---------------------------------------------------------------------------------

# Target group for frontend
resource "aws_lb_target_group" "spotify_appserver_frontend_tg" {
  name        = "spotify-appserver-frontend-tg"
  target_type = "instance"
  port        = 80          # because even though frontend runs on 3000, frontend docker container will expose it on 80 (nginx)
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }

  depends_on = [aws_instance.spotify_app_server]
}


resource "aws_lb_target_group_attachment" "spotify_appserver_frontend_tg_attn" {
  target_group_arn = aws_lb_target_group.spotify_appserver_frontend_tg.arn
  target_id        = aws_instance.spotify_app_server.id
  port             = 80                                   # same port as of aws_lb_target_group
}

# Target group for backend
resource "aws_lb_target_group" "spotify_appserver_backend_tg" {
  name        = "spotify-appserver-backend-tg"
  target_type = "instance"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-499"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }

  depends_on = [aws_instance.spotify_app_server]
}

resource "aws_lb_target_group_attachment" "spotify_appserver_backend_tg_attn" {
  target_group_arn = aws_lb_target_group.spotify_appserver_backend_tg.arn
  target_id        = aws_instance.spotify_app_server.id
  port             = 8000

}

# Application load balancer configuration

resource "aws_lb" "spotify_appserver_alb" {
  name               = "spotify-appserver-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.spotify_alb_sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false # turn it true in production

  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }
}

resource "aws_lb_listener" "spotify_appserver_alb_listener_80" {
  load_balancer_arn = aws_lb.spotify_appserver_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spotify_appserver_frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "alb_api_rule_backend_80" {
  listener_arn = aws_lb_listener.spotify_appserver_alb_listener_80.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spotify_appserver_backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}


resource "aws_lb_listener" "spotify_appserver_alb_listener_443" {

  count = var.is_certificate_issued ? 1 : 0

  load_balancer_arn = aws_lb.spotify_appserver_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.alb_listener_ssl_policy
  certificate_arn   = aws_acm_certificate.spotify_domain_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spotify_appserver_frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "alb_api_rule_backend_443" {
    count = var.is_certificate_issued ? 1 : 0
  listener_arn = aws_lb_listener.spotify_appserver_alb_listener_443[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spotify_appserver_backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

output "alb_dns" {
  value = aws_lb.spotify_appserver_alb.dns_name
}