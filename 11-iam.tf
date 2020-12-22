resource "aws_iam_role" "firehose_role" {
  name = "kinesis-firehose-role"    
#   name = var.kinesis_firehose_role_name
  force_detach_policies = true
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "firehose_policy" {
  name        = "kinesis-firehose-policy"    
#   name        = var.kinesis_firehose_policy_name
  description = "Firehose log processing permissions"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
	  "Effect": "Allow",
	  "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.nginx_logs_s3.arn}",
        "${aws_s3_bucket.nginx_logs_s3.arn}*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction",
        "lambda:GetFunctionConfiguration",
        "logs:PutLogEvents",
        "kinesis:DescribeStream",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords",
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "firehose_attach" {
  name       = "firehose-attachment"
  roles      = [aws_iam_role.firehose_role.name]
  policy_arn = aws_iam_policy.firehose_policy.arn
}


resource "aws_iam_role" "firehose_lambda_role" {
  name = "firehose-lambda-role"
  force_detach_policies = true
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "firehose_lambda_attach" {
  name       = "firehose-lambda-attachment"
  roles      = [aws_iam_role.firehose_lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "ec2_kinesis_agent_role" {
  name = "ec2-kinesis-agent-role"    
  force_detach_policies = true

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ec2_kinesis_agent_policy" {
  name        = "ec2-kinesis-agent-policy"    
  description = "kinesis agent policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "kinesis:PutRecords",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords",
                "kinesis:DescribeStream"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "ec2_kinesis_agent_attach" {
  name       = "ec2-kinesis-agent-attachment"
  roles      = [aws_iam_role.ec2_kinesis_agent_role.name]
  policy_arn = aws_iam_policy.ec2_kinesis_agent_policy.arn
}

resource "aws_iam_instance_profile" "ec2_kinesis_profile" {
  name = "ec2-kinesis-profile"
  role = aws_iam_role.ec2_kinesis_agent_role.name
}