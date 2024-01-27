# Variables
variable "subnet_ids" {
  type    = list(string)
  default = ["subnet-0863e4b6f26dedff5", "subnet-0639400090ec2b020"]  # Update with your actual subnet IDs
}

variable "vpc_id" {
  type    = string
  default = "vpc-017cf710607921ebf"  # Update with your actual VPC ID
}

variable "security_group_ids" {
  type    = list(string)
  default = ["sg-02bc1b90251dd674d"]  # Update with your actual security group IDs
}