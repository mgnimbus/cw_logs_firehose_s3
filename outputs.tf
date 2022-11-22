output "ec2-ID" {
  value = aws_instance.ec2-cw-logs.id
}

output "public-IP" {
  value = aws_instance.ec2-cw-logs.public_ip
}

output "arn_policy" {
  value = aws_iam_policy.ec2_policy.arn
}

