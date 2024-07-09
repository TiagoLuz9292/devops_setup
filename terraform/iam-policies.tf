resource "aws_iam_policy" "s3_read_policy" {
  name        = "S3ReadAccess"
  description = "Policy to grant read access to S3 bucket"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::mybucket",
        "arn:aws:s3:::mybucket/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ec2_full_access_policy" {
  name        = "EC2FullAccess"
  description = "Policy to grant full access to EC2 instances"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
