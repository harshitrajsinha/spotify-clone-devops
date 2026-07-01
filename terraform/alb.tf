# ACM for custom domain
data "aws_acm_certificate" "spotify_domain_certificate" {
  domain   = var.my_domain_name
  statuses = ["ISSUED"]

  tags = {
    Project     = "${var.project_name_tag}"
    Terraform   = "true"
    Environment = "${var.project_env_tag}"
  }
}

# ---------------------------------------------------------------------------------

# Target group for Traefik single endpoint
resource "aws_lb_target_group" "spotify_appserver_tg" {
  name        = "spotify-appserver-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 50
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
  target_group_arn = aws_lb_target_group.spotify_appserver_tg.arn
  target_id        = aws_instance.spotify_app_server.id
  port             = 80
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

output "alb_dns" {
  value = aws_lb.spotify_appserver_alb.dns_name
}


resource "aws_lb_listener" "spotify_appserver_alb_listener_80" {
  load_balancer_arn = aws_lb.spotify_appserver_alb.arn
  port              = 80
  protocol          = "HTTP"

  # default_action {
  #   type             = "forward"
  #   target_group_arn = aws_lb_target_group.spotify_appserver_tg.arn
  # }

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


resource "aws_lb_listener" "spotify_appserver_alb_listener_443" {

  load_balancer_arn = aws_lb.spotify_appserver_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.alb_listener_ssl_policy
  certificate_arn   = data.aws_acm_certificate.spotify_domain_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spotify_appserver_tg.arn
  }
}