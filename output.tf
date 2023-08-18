output "function_name" {
    description = "Lambda function name"
    value = aws_lambda_function.terraform_lambda_kms.function_name
}

output "cloud_watch_arn" {
    description = "Cloudwatch ARN"
    value = aws_cloudwatch_log_group.terraform_lambda_kms_cloudwatch.arn
}

output "kms_key" {
    description = "KMS Key ARN"
    value = aws_kms_key.terraform_lambda_kms_key.arn  
}