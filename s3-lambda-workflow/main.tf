resource "aws_s3_bucket" "demo_bucket" {
  bucket = var.bucket_name
}

resource "aws_sqs_queue" "file_queue" {
  name = "file-upload-queue"
}

resource "aws_sqs_queue_policy" "queue_policy" {

  queue_url = aws_sqs_queue.file_queue.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "s3.amazonaws.com"
        }

        Action = "sqs:SendMessage"

        Resource = aws_sqs_queue.file_queue.arn

        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.demo_bucket.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "bucket_notification" {

  bucket = aws_s3_bucket.demo_bucket.id

  queue {

    queue_arn = aws_sqs_queue.file_queue.arn

    events = [
      "s3:ObjectCreated:*"
    ]
  }

  depends_on = [
    aws_sqs_queue_policy.queue_policy
  ]
}

resource "aws_iam_role" "lambda_role" {

  name = "s3-sqs-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {

  role       = aws_iam_role.lambda_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_sqs_policy" {

  name = "lambda-sqs-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]

        Resource = aws_sqs_queue.file_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_sqs" {

  role       = aws_iam_role.lambda_role.name

  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

resource "aws_lambda_function" "file_processor" {

  filename         = "lambda/lambda.zip"

  function_name    = "file-upload-processor"

  role             = aws_iam_role.lambda_role.arn

  handler          = "lambda_function.lambda_handler"

  runtime          = "python3.12"

  source_code_hash = filebase64sha256("lambda/lambda.zip")
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {

  event_source_arn = aws_sqs_queue.file_queue.arn

  function_name = aws_lambda_function.file_processor.arn

  batch_size = 1
}