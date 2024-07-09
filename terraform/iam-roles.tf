resource "aws_iam_role" "developer_role" {
  name = "developer-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "developer_s3_policy" {
  role       = aws_iam_role.developer_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

resource "aws_iam_role_policy_attachment" "developer_ec2_policy" {
  role       = aws_iam_role.developer_role.name
  policy_arn = aws_iam_policy.ec2_full_access_policy.arn
}

resource "aws_iam_instance_profile" "developer_instance_profile" {
  name = "developer-instance-profile"
  role = aws_iam_role.developer_role.name
}
