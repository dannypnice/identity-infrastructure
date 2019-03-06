variable "aws_region" {
  description = "AWS region to deploy to"
  default     = "eu-west-1"
}

variable "public_key" {
  description = "Public key to use for deployment"
}

variable "count" {
  default = "2"
}
