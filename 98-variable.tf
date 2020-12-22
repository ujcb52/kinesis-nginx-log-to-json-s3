variable "handler" {
  description = "Lambda Function handler (entrypoint)"
  default     = "lambda_function.lambda_handler"
}

variable "runtime" {
  description = "Lambda Function runtime"
  default     = "python3.7"
}

variable "timeout" {
  description = "Lambda Function timeout in seconds"
  default     = 60
}

variable "amazon_linux_ami" {
  description = "Amazon Linux 2 AMI"
  default     = "ami-03461b78fdba0ff9d"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  default     = "t3.micro"
}
variable "instance_user_data" {
  description = "EC2 Kinesis Agent Scripts File Name"
  default     = "instance_install.sh"
}

variable "instance_key_name" {
  description = "EC2 Keypair Name"
  default     = "jwpem"
}

# variable "instance_subnet_id" {
#   description = "EC2 Instance Subnet ID"
#   default     = "subnet-ff993109"
# }

# variable "instance_sg_id" {
#   description = "EC2 Instance Security Group ID"
#   default     = "sg-3c5f4b87"
# }

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default     = "10.10.0.0/20"
}

variable "public_subnet_cidr" {
  description = "CIDR for the Public Subnet"
  default     = "10.10.0.0/24"
}
