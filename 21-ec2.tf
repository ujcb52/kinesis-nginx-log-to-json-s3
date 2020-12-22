resource "aws_instance" "web-01" {
  ami           = var.amazon_linux_ami
  instance_type = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_kinesis_profile.name
  vpc_security_group_ids = [aws_security_group.ec2_public_sg.id]
  subnet_id     = aws_subnet.ap_northeast_2a_public.id
  key_name      = var.instance_key_name
  user_data     = file(var.instance_user_data)

  # Temporary IP allocation for test
  associate_public_ip_address = true

  tags = {
    Name = "Nginx-Web-01"
  }
}