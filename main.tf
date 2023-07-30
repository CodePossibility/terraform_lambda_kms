terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
    archive = {
        source = "hashicorp/archive"
        version = "~> 2.2.0"
    }
  }
  required_version = "~> 1.0"
}

provider "aws" {
    region = var.aws_region
}

resource "aws_kms_key" "sandbox_kms_lambda_key" {
    description = "Key for secret encription and decryption"
    is_enabled = true
}

resource "aws_kms_alias" "sandbox_kms_lambda_key_alias" {
    name = "alias/sandbox_kms_lambda_key"
    target_key_id = aws_kms_key.sandbox_kms_lambda_key.key_id
}

data "aws_iam_policy_document" "sandbox_kms_lambda_policy_document" {
    statement {
      sid = "1"

      actions = [
        "kms:Decrypt"
      ]

      resources = [
        "*",
      ]

    #   principals {
    #     type = "AWS"

    #     identifiers = [
    #         "${aws_iam_role.sandbox_kms_lambda_role.name}"
    #     ]
    #   }
    }
}

resource "aws_iam_policy" "sandbox_kms_lambda_policy" {
    name = "sandbox_kms_lambda_policy"
    policy = data.aws_iam_policy_document.sandbox_kms_lambda_policy_document.json
}

resource "aws_iam_role" "sandbox_kms_lambda_role" {
    name = "sandbox_kms_lambda_role"

    assume_role_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_policy_attachment" "sandbox_kms_lambda_policy_attachment" {
    name = "sandbox_kms_lambda_policy_attachment"
    roles = [ aws_iam_role.sandbox_kms_lambda_role.name ]
    policy_arn = aws_iam_policy.sandbox_kms_lambda_policy.arn
}

data "archive_file" "sandbox_kms_lambda_source_archive" {
    type = "zip"

    source_dir = "${path.module}/src"
    output_path = "${path.module}/my-deployment.zip"
}

resource "aws_kms_ciphertext" "api_key" {
    key_id = aws_kms_key.sandbox_kms_lambda_key.key_id
    plaintext = "${var.API_KEY}"  
}

resource "aws_lambda_function" "sandbox_kms_lambda" {
    function_name = "sandbox_kms_lambda"
    filename = "${path.module}/my-deployment.zip"

    runtime = "python3.9"
    handler = "app.lambda_handler"

    source_code_hash = data.archive_file.sandbox_kms_lambda_source_archive.output_base64sha256

    role = aws_iam_role.sandbox_kms_lambda_role.arn

    kms_key_arn = aws_kms_key.sandbox_kms_lambda_key.arn

    environment {
      variables = {
        api_key = aws_kms_ciphertext.api_key.ciphertext_blob
      }
    }
}

resource "aws_cloudwatch_log_group" "sandbox_kms_lambda_cloudwatch" {
    name = "/aws/lambda/${aws_lambda_function.sandbox_kms_lambda.function_name}"

    retention_in_days = 30
}