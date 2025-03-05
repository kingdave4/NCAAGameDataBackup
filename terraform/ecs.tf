# ecs.tf

resource "aws_ecs_cluster" "my_cluster" {
  name = "${var.project_name}-cluster"
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "my_task" {
  family                   = "${var.project_name}-task"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = templatefile("${path.module}/container_definitions.tpl", {
    ecr_image_url              = "${aws_ecr_repository.my_ecr.repository_url}:latest"
    log_group_name             = aws_cloudwatch_log_group.ecs_log_group.name
    aws_region                 = var.aws_region
    bucket_name                = var.s3_bucket_name
    rapidapi_ssm_parameter_arn = var.rapidapi_ssm_parameter_arn
    mediaconvert_endpoint      = var.mediaconvert_endpoint
    mediaconvert_role_arn      = var.mediaconvert_role_arn
  })
}
