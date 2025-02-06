variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "instance_id" {
  description = "EC2 Instance ID to manage"
  default     = "i-05d6dd6521d0c4e0a"
}

variable "stop_schedule" {
  description = "CRON schedule for stopping EC2"
  default     = "cron(0 22 ? * MON-FRI *)" # 22:00 UTC (Stop EC2)
}

variable "start_schedule" {
  description = "CRON schedule for starting EC2"
  default     = "cron(0 10 ? * MON-FRI *)" # 10:00 UTC (Start EC2)
}