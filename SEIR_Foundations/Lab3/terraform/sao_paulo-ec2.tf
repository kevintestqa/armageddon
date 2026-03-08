############################################
# EC2 Instance (App Host)
############################################

# Explanation: This is your “Han Solo box”—it talks to RDS and complains loudly when the DB is down.

resource "aws_instance" "liberdade_ec2_01" {
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.liberdade_public_subnets[0].id
  vpc_security_group_ids      = [aws_security_group.liberdade_ec2_sg01.id]
  iam_instance_profile        = aws_iam_instance_profile.liberdade_instance_profile01.name
  user_data_replace_on_change = true
  associate_public_ip_address = true
  provider                    = aws.sao_paulo

  user_data = file("${path.module}/3a_user_data.sh")
  //depends_on = [aws_db_instance.shinjuku_rds01]

  tags = {
    Name = "${local.liberdade}-ec2_01-public-lab1A"
  }
}

# ############################################
# # Move EC2 into PRIVATE subnet (no public IP)
# ############################################

# # Explanation: liberdade hates exposure—private subnets keep your compute off the public holonet.  EC201 is used in Bonus_B
resource "aws_instance" "liberdade_ec201" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.liberdade_private_subnets[0].id
  vpc_security_group_ids = [aws_security_group.liberdade_ec2_sg01.id] #This would add a security group on port 80 instead of using only the ALB
  iam_instance_profile   = aws_iam_instance_profile.liberdade_instance_profile01.name
  security_groups        = [aws_security_group.liberdade_alb_sg01.id]
  provider               = aws.sao_paulo

  # TODO: Students should remove/disable SSH inbound rules entirely and rely on SSM.
  # TODO: Students add user_data that installs app + CW agent; for true hard mode use a baked AMI.
  user_data                   = file("${path.module}/3a_user_data.sh")
  user_data_replace_on_change = true

  tags = {
    Name = "${local.liberdade}-ec201-private-bonus-labs_A"
  }
}