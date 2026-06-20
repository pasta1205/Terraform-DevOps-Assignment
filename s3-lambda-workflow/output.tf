output "bucket_name" {
  value = aws_s3_bucket.demo_bucket.bucket
}

output "queue_url" {
  value = aws_sqs_queue.file_queue.id
}

output "lambda_name" {
  value = aws_lambda_function.file_processor.function_name
}