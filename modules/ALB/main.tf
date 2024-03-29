
data "aws_security_group" "alb_sg" {
  name = "load_balancer-http-https"
}



resource "aws_lb" "application-lb" {
  name                       = var.alb_name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [data.aws_security_group.alb_sg.id]
  subnets                    = var.subnets[*]
  enable_deletion_protection = true

  tags = var.tags
}

#Target group and attachment for Magento2 web servers
resource "aws_lb_target_group" "dev-lb-tg" {
  name        = var.alb_tg_name
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    healthy_threshold   = var.health_check["healthy_threshold"]
    interval            = var.health_check["interval"]
    unhealthy_threshold = var.health_check["unhealthy_threshold"]
    timeout             = var.health_check["timeout"]
    path                = var.health_check["path"]
    port                = var.health_check["port"]
  }
  tags = {
    Name = "ec2-target-group"
  }
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.dev-lb-tg.arn
  target_id        = var.instance_id
  port             = 80
}


resource "aws_lb_listener" "lb-https-listener" {
  load_balancer_arn = aws_lb.application-lb.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.aws-ssl-cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev-lb-tg.arn
  }
}

resource "aws_lb_listener" "lb-http-listener" {
  load_balancer_arn = aws_lb.application-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}



#ACM CONFIGURATION
resource "aws_acm_certificate" "aws-ssl-cert" {
  domain_name       = var.dns-name
  validation_method = "DNS"
  tags = {
    Name = "Webservers-ACM"
  }

}

#Validates ACM issued certificate via Route53
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.aws-ssl-cert.arn
  for_each                = aws_route53_record.cert_validation
  validation_record_fqdns = [aws_route53_record.cert_validation[each.key].fqdn]
}