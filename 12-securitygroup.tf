resource "aws_security_group" "ec2_public_sg" {
    name = "vpc-public-ec2"
    description = "EC2 launched in public subnet"

      
    ingress {
        description = "Test Web1"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        # cidr_blocks = [var.public_subnet_cidr]
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = aws_vpc.vpc_web1.id

    tags = {
        Name = "EC2-Public-SG1"
    }
}