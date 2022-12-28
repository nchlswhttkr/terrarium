resource "aws_ecs_cluster" "terrarium" {
  name = "terrarium"
}

resource "aws_ecs_task_definition" "terraria" {
  family                   = "terrarium"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = aws_iam_role.execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  network_mode             = "awsvpc"

  volume {
    name = "worlds"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.worlds.id
    }

  }

  container_definitions = jsonencode([
    {
      name      = "server"
      image     = "ghcr.io/nchlswhttkr/terrarium:main"
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = 41641
          protocol      = "udp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "terraria"
          "awslogs-stream-prefix" = "terraria"
          "awslogs-region"        = "ap-southeast-2"
          "awslogs-create-group"  = "true" # TODO: Fix and provision log group via Terraform
        }
      }
      mountPoints = [
        {
          sourceVolume  = "worlds"
          containerPath = "/terrarium/worlds"
        }
      ]
      environment = [
        {
          name  = "CONFIG_S3_BUCKET"
          value = aws_s3_bucket.config.bucket
        }
      ]
    }
  ])
}

resource "aws_iam_role" "task_role" {
  name               = "TerrariumTaskRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role" "execution_role" {
  name               = "TerrariumTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  version = "2012-10-17"
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "create_logs" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.create_logs.arn
}

resource "aws_iam_policy" "create_logs" {
  policy = data.aws_iam_policy_document.create_logs.json
}

data "aws_iam_policy_document" "create_logs" {
  version = "2012-10-17"
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "read_bucket" {
  policy = data.aws_iam_policy_document.read_bucket.json
}

resource "aws_iam_role_policy_attachment" "read_bucket" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.read_bucket.arn
}

data "aws_iam_policy_document" "read_bucket" {
  version = "2012-10-17"
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.config.arn}/config/*"]
  }

  statement {
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_key.ssm_default.arn]
  }

  statement {
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.tailscale_authentication_key.arn]
  }
}

data "aws_kms_key" "ssm_default" {
  key_id = "alias/aws/ssm"

  depends_on = [
    aws_ssm_parameter.tailscale_authentication_key
  ]
}
