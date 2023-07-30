output "function_name" {
    description = "Lambda function name"
    value = aws_lambda_function.sandbox_kms_lambda.function_name
}

output "cloud_watch_arn" {
    description = "Cloudwatch ARN"
    value = aws_cloudwatch_log_group.sandbox_kms_lambda_cloudwatch.arn
}

output "kms_key" {
    description = "KMS Key ARN"
    value = aws_kms_key.sandbox_kms_lambda_key.arn  
}