#! /bin/bash

# Instance Identity Metadata Reference - https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
sudo yum update -y
sudo yum install awslogs -y
sudo service awslogsd start
sudo systemctl enable awslogsd
sudo yum install amazon-cloudwatch-agent -y
sudo systemctl status amazon-ssm-agent