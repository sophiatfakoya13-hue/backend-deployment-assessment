
variable "aws_region" {
  description = "AWS region where infrastructure will be deployed"
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance type for all servers"
  type        = string
  default     = "t3.micro"
}

variable "my_ip" {
  description = "Your current public IP address in CIDR notation"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the AWS EC2 key pair"
  type        = string
}
