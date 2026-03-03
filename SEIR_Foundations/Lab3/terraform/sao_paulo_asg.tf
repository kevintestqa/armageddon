resource "aws_autoscaling_group" "liberdade_asg01" {
  name                      = "${vars.liberdade}-asg01"
  min_size                  = var.asg_minimum_size
  max_size                  = var.asg_maximum_size
  desired_capacity          = var.asg_desired_capacity
  vpc_zone_identifier       = aws_subnet.liberdade_private_subnets[*].id
  health_check_type         = "ELB"
  health_check_grace_period = 60
  target_group_arns         = [aws_lb_target_group.liberdade_tg01.arn]

  launch_template {
    id      = aws_launch_template.liberdade_lt01.id
    version = "$Latest"
  }

  tag {
    key                 = "Resource"
    value               = "${vars.liberdade}-asg01"
    propagate_at_launch = true
  }
}