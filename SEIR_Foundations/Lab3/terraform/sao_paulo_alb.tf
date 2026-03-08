##############################################
# # Application Load Balancer
# ############################################

# # Explanation: The ALB is your public customs checkpoint — it speaks TLS and forwards to private targets.
resource "aws_lb" "liberdade_alb01" {
  name               = "${var.liberdade}-alb01"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.liberdade_alb_sg01.id]
  subnets         = aws_subnet.liberdade_public_subnets[*].id
  provider        = aws.sao_paulo
}

# ############################################
# # Target Group + Attachment
# ############################################

# # Explanation: Target groups are liberdade’s “who do I forward to?” list — private EC2 lives here.
resource "aws_lb_target_group" "liberdade_tg01" {
  name     = "liberdade-tg01"
  port     = local.ports_http
  protocol = "HTTP"
  vpc_id   = aws_vpc.liberdade_vpc01.id
  provider = aws.sao_paulo

  # TODO: students set health check path to something real (e.g., /health)
  health_check {
    enabled             = true
    interval            = 30 #TODO: adjust intervals to something more realistic
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.liberdade}-tg01"
  }
}

# # Explanation: liberdade personally introduces the ALB to the private EC2 — “this is my friend, don’t shoot.”
resource "aws_lb_target_group_attachment" "liberdade_tg_attach01" {
  target_group_arn = aws_lb_target_group.liberdade_tg01.arn
  target_id        = aws_instance.liberdade_ec201.id
  port             = local.ports_http
  provider         = aws.sao_paulo
}

###############################################
# # ALB Listeners: HTTP -> HTTPS redirect, HTTPS -> TG
# ############################################

# Explanation: HTTP listener is the decoy airlock — it redirects everyone to the secure entrance.
resource "aws_lb_listener" "liberdade_http_listener01" {
  load_balancer_arn = aws_lb.liberdade_alb01.arn
  port              = local.ports_http
  protocol          = "HTTP"
  provider          = aws.sao_paulo

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "404"
    }
  }
}

# # Explanation: HTTPS listener is the real hangar bay — TLS terminates here, then traffic goes to private targets.
# resource "aws_lb_listener" "liberdade_https_listener01" {
#   load_balancer_arn = aws_lb.liberdade_alb01.arn
#   port              = local.ports_https
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   provider          = aws.sao_paulo

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.liberdade_tg01.arn
#   }
# }