resource "aws_launch_template" "liberdade_lt01" {
  name_prefix   = "${vars.liberdade}-lt01"
  image_id      = data.aws_ami.al2.id
  instance_type = var.ec2_instance_type

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = false
    security_groups             = [aws_security_group.liberdade_asg_sg01.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${vars.liberdade}-asg-ec2-launched"
    }
  }
}