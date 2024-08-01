variable "asg_name" {
  description = "The name of the Auto Scaling Group"
  type        = string
}

variable "scale_out_policy_arn" {
  description = "ARN of the scale out policy"
  type        = string
}

variable "scale_in_policy_arn" {
  description = "ARN of the scale in policy"
  type        = string
}

variable "high_cpu_threshold" {
  description = "High CPU utilization threshold"
  type        = number
}

variable "low_cpu_threshold" {
  description = "Low CPU utilization threshold"
  type        = number
}

variable "evaluation_periods" {
  description = "Evaluation periods for the alarms"
  type        = number
}

variable "period" {
  description = "Period for the alarms"
  type        = number
}
