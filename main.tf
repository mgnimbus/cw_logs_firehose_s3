resource "aws_iam_policy" "ec2_policy" {
  name = "ec2_policy"
  path = "/"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ],
        "Resource" : "*"
      },
    ]
  })
}
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ec2-attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}


resource "aws_iam_instance_profile" "ec2_cloudwatch_profile" {
  name = "ec2_cloudwatchlogs"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "ec2-cw-logs" {
  ami                  = var.ami
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_cloudwatch_profile.name
  key_name             = "mgdev"

  user_data = file("cw-agent.sh")

  tags = {
    "Name" = "cloud_watch_logs"
  }
}

resource "aws_iam_role" "firehose_s3_role" {
  name = "firehose_s3_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_policy" "firehose_s3_policy" {
  name = "firehose_s3_policy"
  path = "/"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
        "s3:PutObject"],
        "Resource" : [
          "arn:aws:s3:::*",
        "arn:aws:s3:::*/*"]
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "firehouse-attach" {
  role       = aws_iam_role.firehose_s3_role.name
  policy_arn = aws_iam_policy.firehose_s3_policy.arn
}

resource "aws_iam_role" "cwl_firehose_role" {
  name = "cwl_firehose_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "logs.us-east-1.amazonaws.com"

        }
      },
    ]
  })
}
resource "aws_iam_policy" "cwl_firehose_policy" {
  name = "cwl_firehose_policy"
  path = "/"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : ["firehose:*"],
        "Resource" : [
        "arn:aws:firehose:*"]
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "cwl-attach" {
  role       = aws_iam_role.cwl_firehose_role.name
  policy_arn = aws_iam_policy.cwl_firehose_policy.arn
}


resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "tf-test-stream"
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.firehose_s3_role.arn
    bucket_arn = "arn:aws:s3:::tf-test-stream"
  }
}

output "arn_data_stream" {
  value = aws_kinesis_firehose_delivery_stream.test_stream.id
}

resource "aws_cloudwatch_log_subscription_filter" "cwl_firehose_s3" {

  destination_arn = aws_kinesis_firehose_delivery_stream.test_stream.arn
  role_arn        = aws_iam_role.cwl_firehose_role.arn
  filter_pattern  = "ec2"
  log_group_name  = "/var/log/messages"
  name            = "tf-test-stream"
  #distribution    = "Random"
}
