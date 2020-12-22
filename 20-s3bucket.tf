resource "aws_s3_bucket" "nginx_logs_s3" {
  bucket = "nginx-access-logs-s3"
  acl    = "private"
  # delete a non-empty AWS S3 bucket
  force_destroy = false

  tags = {
    Environment = "nginx_app"
  }
}