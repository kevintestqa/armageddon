resource "aws_launch_template" "liberdade_lt01" {
  name_prefix   = "${var.liberdade}-lt01"
  image_id      = var.ec2_ami_id
  instance_type = var.ec2_instance_type
  provider      = aws.sao_paulo
  //user_data = filebase64("${path.module}/3a_user_data.sh")
  user_data = filebase64("${path.module}/test.sh")

  iam_instance_profile {
    name = aws_iam_instance_profile.liberdade_instance_profile01.name
  }

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = false
    security_groups             = [aws_security_group.liberdade_asg_sg01.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.liberdade}-asg-ec2-launched"
    }
  }
}