variable "tags" {
  default = {
    Owner   = "Soso Kumladze"
    Project = "VRTX-TRP"
  }
}

variable "subnet_id" {
  type = list
}

variable "ec2_name" {
  type = string
  default = "test_ec2"
}
