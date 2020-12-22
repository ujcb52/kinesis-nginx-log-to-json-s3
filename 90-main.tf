resource "aws_kinesis_stream" "nginx_stream" {
  name             = "nginx-access-logs"
  shard_count      = 1
  retention_period = 24

  # shard_level_metrics = [
  #   "IncomingBytes",
  #   "OutgoingBytes",
  # ]

  tags = {
    Environment = "nginx_app"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "nginx-logs-to-s3"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.nginx_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.nginx_logs_s3.arn

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.lambda_processor.arn}:$LATEST"
        }
      }
    }
  }
}

resource "aws_lambda_function" "lambda_processor" {
  filename      = "lambda_function.zip"
  function_name = "firehose-lambda-processor"
  role          = aws_iam_role.firehose_lambda_role.arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
}