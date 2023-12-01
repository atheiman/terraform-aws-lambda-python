terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_partition" "current" {}

locals {
  lambda_function_name          = "MyFunction"
  lambda_runtime                = "python3.11"
  lambda_root                   = "${path.module}/lambda"
  lambda_layer_root             = "${local.lambda_root}/layer"
  lambda_layer_requirements_txt = "${local.lambda_layer_root}/requirements.txt"
  # Python deps should be zipped into a `/python/` directory
  # https://docs.aws.amazon.com/lambda/latest/dg/packaging-layers.html#packaging-layers-paths
  lambda_layer_lib_root = "${local.lambda_layer_root}/python"
  lambda_function_root  = "${local.lambda_root}/function"
}

resource "aws_iam_role" "lambda" {
  name_prefix = "Lambda-${local.lambda_function_name}-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policy {
    name = "Inline"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["ec2:DescribeInstances"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = 14
}

resource "null_resource" "pip_install" {
  provisioner "local-exec" {
    command = "pip install --quiet --quiet --requirement ${local.lambda_layer_requirements_txt} --target ${local.lambda_layer_lib_root}"
  }

  triggers = {
    # Use this to force an update of pip dependencies
    #always_run   = timestamp()
    requirements = filemd5(local.lambda_layer_requirements_txt)
  }
}

data "archive_file" "lambda_layer" {
  depends_on  = [null_resource.pip_install]
  type        = "zip"
  source_dir  = local.lambda_layer_root
  output_path = "${path.module}/lambda_layer.zip"
}

resource "aws_lambda_layer_version" "layer" {
  layer_name          = "${local.lambda_function_name}-pip-requirements"
  filename            = data.archive_file.lambda_layer.output_path
  source_code_hash    = data.archive_file.lambda_layer.output_base64sha256
  compatible_runtimes = [local.lambda_runtime]

  # Ensure the new layer version is created before the old layer version is deleted (avoids /
  # reduces function downtime). An alternative option is to set `skip_destroy = true`, but that
  # will result in unused layers which incur a cost.
  lifecycle {
    create_before_destroy = true
  }
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = local.lambda_function_root
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "lambda" {
  # Ensure log group is created by terraform before lambda function executes and
  # creates the log group.
  depends_on = [aws_cloudwatch_log_group.lambda]

  filename         = data.archive_file.lambda_function.output_path
  function_name    = local.lambda_function_name
  role             = aws_iam_role.lambda.arn
  timeout          = 10
  handler          = "lambda.handler"
  runtime          = local.lambda_runtime
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  layers           = [aws_lambda_layer_version.layer.arn]
}
