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

resource "aws_kms_key" "terraform_lambda_kms_key" {
    description = "Key for secret encription and decryption"
    is_enabled = true
}

resource "aws_kms_alias" "terraform_lambda_kms_key_alias" {
    name = "alias/terraform_lambda_kms_key"
    target_key_id = aws_kms_key.terraform_lambda_kms_key.key_id
}

data "aws_iam_policy_document" "terraform_lambda_kms_policy_document" {
    version = "2012-10-17"
    statement {
      sid = "terraform_lambda_kms_policy_document"

      actions = [
        "kms:Decrypt"
      ]

      resources = [
        "*",
      ]
    }
}

resource "aws_iam_policy" "terraform_lambda_kms_policy" {
    name = "terraform_lambda_kms_policy"
    policy = data.aws_iam_policy_document.terraform_lambda_kms_policy_document.json
}

resource "aws_iam_role" "terraform_lambda_kms_role" {
    name = "terraform_lambda_kms_role"

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

resource "aws_iam_policy_attachment" "terraform_lambda_kms_policy_attachment" {
    name = "terraform_lambda_kms_policy_attachment"
    roles = [ aws_iam_role.terraform_lambda_kms_role.name ]
    policy_arn = aws_iam_policy.terraform_lambda_kms_policy.arn
}

data "archive_file" "terraform_lambda_kms_source_archive" {
    type = "zip"

    source_dir = "${path.module}/src"
    output_path = "${path.module}/my-deployment.zip"
}

resource "aws_kms_ciphertext" "api_key" {
    key_id = aws_kms_key.terraform_lambda_kms_key.key_id
    plaintext = "${var.API_KEY}"  
}

resource "aws_lambda_function" "terraform_lambda_kms" {
    function_name = "terraform_lambda_kms"
    filename = "${path.module}/my-deployment.zip"

    runtime = "python3.9"
    handler = "app.lambda_handler"

    source_code_hash = data.archive_file.terraform_lambda_kms_source_archive.output_base64sha256

    role = aws_iam_role.terraform_lambda_kms_role.arn

    kms_key_arn = aws_kms_key.terraform_lambda_kms_key.arn

    environment {
      variables = {
        api_key = aws_kms_ciphertext.api_key.ciphertext_blob
      }
    }
}

resource "aws_cloudwatch_log_group" "terraform_lambda_kms_cloudwatch" {
    name = "/aws/lambda/${aws_lambda_function.terraform_lambda_kms.function_name}"

    retention_in_days = 30
}