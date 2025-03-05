# iam.tf

# Retrieve AWS account information
data "aws_caller_identity" "current" {}

# Define the ECS task policy for Secrets Manager access
data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    sid       = "AllowSecretsManagerAccess"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:us-east-1:636772248290:secret:my-api-key-S7JPgN"]
  }
}

# Define the trust relationship for ECS tasks
data "aws_iam_policy_document" "ecs_task_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Create the ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust.json
}

# Attach the AWS-managed ECS Task Execution policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Define the custom IAM policy document
data "aws_iam_policy_document" "ecs_custom_doc" {
  # 1) S3 Permissions
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:CreateBucket", "s3:ListBucket"]
    effect    = "Allow"
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  # 2) SSM Parameter Store Permissions
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterHistory"
    ]
    effect    = "Allow"
    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/highlight-pipeline-final/*",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/NCAAHighlightsBackup/*",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/myproject/*"
    ]
  }

  # 3) MediaConvert Permissions
  statement {
    actions   = [
      "mediaconvert:CreateJob",
      "mediaconvert:GetJob",
      "mediaconvert:ListJobs"
    ]
    effect    = "Allow"
    resources = ["*"]  # MediaConvert requires "*" for resource ARN
  }

  # 4) DynamoDB Permissions - Added for backup operations
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:DescribeTable"
    ]
    effect    = "Allow"
    resources = [
      "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/SportsHighlights"
    ]
  }
}

# Create the custom IAM policy
resource "aws_iam_policy" "ecs_custom_policy" {
  name   = "${var.project_name}-ecs-custom-policy"
  policy = data.aws_iam_policy_document.ecs_custom_doc.json
}

# Attach the custom IAM policy to the ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_custom_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_custom_policy.arn
}

# Attach the Secrets Manager access policy (inline) to the ECS task execution role
resource "aws_iam_role_policy" "ecs_task_secrets_policy" {
  name   = "${var.project_name}-ecs-task-secrets-policy"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = data.aws_iam_policy_document.ecs_task_policy.json
}

# Allow the ECS task execution role to pass the MediaConvert role
resource "aws_iam_role_policy" "ecs_task_pass_role_policy" {
  name   = "${var.project_name}-ecs-task-pass-role-policy"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowPassMediaConvertRole",
        "Effect": "Allow",
        "Action": "iam:PassRole",
        "Resource": aws_iam_role.mediaconvert_role.arn,
        "Condition": {
          "StringEquals": {
            "iam:PassedToService": "mediaconvert.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Define the trust relationship for MediaConvert
data "aws_iam_policy_document" "mediaconvert_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["mediaconvert.amazonaws.com"]
    }
  }
}

# Create the MediaConvert role
resource "aws_iam_role" "mediaconvert_role" {
  name               = "${var.project_name}-mediaconvert-role"
  assume_role_policy = data.aws_iam_policy_document.mediaconvert_trust.json
}

# Define the MediaConvert policy document
data "aws_iam_policy_document" "mediaconvert_policy_doc" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
  }
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    effect    = "Allow"
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}/*"]
  }
}

# Create the MediaConvert policy
resource "aws_iam_policy" "mediaconvert_policy" {
  name   = "${var.project_name}-mediaconvert-s3-logs"
  policy = data.aws_iam_policy_document.mediaconvert_policy_doc.json
}

# Attach the MediaConvert policy to the MediaConvert role
resource "aws_iam_role_policy_attachment" "mediaconvert_attach" {
  role       = aws_iam_role.mediaconvert_role.name
  policy_arn = aws_iam_policy.mediaconvert_policy.arn
}
