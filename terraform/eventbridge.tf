# Create an EventBridge rule to trigger every 10 minutes
resource "aws_cloudwatch_event_rule" "daily_schedule" {
  name                = "${var.project_name}-daily-schedule"
  schedule_expression = "rate(10 minutes)"
  description         = "Triggers the NCAA_GamehighLight ECS task every 10 minutes"
}


# Create an IAM role that EventBridge will assume to run the ECS task
resource "aws_iam_role" "ecs_events_role" {
  name = "${var.project_name}-ecs-events-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "events.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}


# Attach a policy to allow the EventBridge rule to run your ECS task
resource "aws_iam_role_policy" "ecs_events_policy" {
  name = "${var.project_name}-ecs-events-policy"
  role = aws_iam_role.ecs_events_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "ecs:RunTask",
        "Effect": "Allow",
        "Resource": [
          aws_ecs_task_definition.my_task.arn,
          aws_ecs_cluster.my_cluster.arn
        ]
      },
      {
        "Action": "iam:PassRole",
        "Effect": "Allow",
        "Resource": aws_iam_role.ecs_task_execution_role.arn
      }
    ]
  })
}

# Create an EventBridge target to trigger your ECS task
resource "aws_cloudwatch_event_target" "ecs_target" {
  rule      = aws_cloudwatch_event_rule.daily_schedule.name
  target_id = "ecs-task-target"
  arn       = aws_ecs_cluster.my_cluster.arn

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.my_task.arn
    launch_type         = "FARGATE"
    network_configuration {
      subnets          = [aws_subnet.public.id]             # List of subnet IDs
      security_groups  = [aws_security_group.ecs_task.id]   # List of security group IDs
      assign_public_ip = true
    }
    task_count = 1
  }

  # Associate the EventBridge target with the IAM role for ECS events
  role_arn = aws_iam_role.ecs_events_role.arn
}
