provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "us-east-1"
}

variable "instance_id" {
  default = "i-05d6dd6521d0c4e0a"
}

##############################
# IAM Role & Policy for SSM Automation
##############################

resource "aws_iam_role" "ssm_automation_role" {
  name = "SSM_Automation_EC2_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ssm_automation_policy" {
  name        = "SSM_Automation_EC2_Policy"
  description = "Allows SSM automation to stop/start EC2 instances"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:StartAutomationExecution",
          "ssm:GetAutomationExecution"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_automation_policy" {
  role       = aws_iam_role.ssm_automation_role.name
  policy_arn = aws_iam_policy.ssm_automation_policy.arn
}

##############################
# Maintenance Window for Stopping EC2 (Weekdays Only)
##############################

variable "stop_schedule" {
  default = "cron(0 22 ? * MON-FRI *)" # 22:00 UTC Monday-Friday
}

resource "aws_ssm_maintenance_window" "stop_ec2_window" {
  name                       = "StopEC2Instances"
  schedule                   = var.stop_schedule
  schedule_timezone          = "UTC"
  duration                   = 1
  cutoff                     = 0
  allow_unassociated_targets = true
}

resource "aws_ssm_maintenance_window_task" "stop_ec2_task" {
  window_id        = aws_ssm_maintenance_window.stop_ec2_window.id
  name             = "StopEC2Task"
  task_type        = "AUTOMATION"
  task_arn         = "AWS-StopEC2Instance"
  priority         = 1
  max_concurrency  = "1"
  max_errors       = "1"
  service_role_arn = aws_iam_role.ssm_automation_role.arn

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "InstanceId"
        values = [var.instance_id]
      }
    }
  }
}

##############################
# Maintenance Window for Starting EC2 (Weekdays Only)
##############################

variable "start_schedule" {
  default = "cron(0 10 ? * MON-FRI *)" # 10:00 UTC Monday-Friday
}

resource "aws_ssm_maintenance_window" "start_ec2_window" {
  name                       = "StartEC2Instances"
  schedule                   = var.start_schedule
  schedule_timezone          = "UTC"
  duration                   = 1
  cutoff                     = 0
  allow_unassociated_targets = true
}

resource "aws_ssm_maintenance_window_task" "start_ec2_task" {
  window_id        = aws_ssm_maintenance_window.start_ec2_window.id
  name             = "StartEC2Task"
  task_type        = "AUTOMATION"
  task_arn         = "AWS-StartEC2Instance"
  priority         = 1
  max_concurrency  = "1"
  max_errors       = "1"
  service_role_arn = aws_iam_role.ssm_automation_role.arn

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "InstanceId"
        values = [var.instance_id]
      }
    }
  }
}
