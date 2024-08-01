variable "region" {
  description = "The AWS region to deploy resources."
  type        = string
}

variable "autoscaling_group_name" {
  description = "The name of the Auto Scaling group."
  type        = string
}
