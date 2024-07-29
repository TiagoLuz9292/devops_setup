resource "aws_iam_role" "admin_role" {
  name = "admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "admin_policy" {
  name        = "admin-policy"
  description = "Policy for admin servers to access S3 bucket and DynamoDB table"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::terraform-state-2024-1a",
          "arn:aws:s3:::terraform-state-2024-1a/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ],
        Resource = "arn:aws:dynamodb:eu-north-1:891377403327:table/terraform-state-locks"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeTags",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstanceCreditSpecifications",
          "ec2:DescribeAddresses",
          "ec2:DescribeAddressesAttribute",
          "ec2:StopInstances",
          "ec2:ModifyInstanceAttribute",
          "ec2:StartInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "admin_policy_attachment" {
  role       = aws_iam_role.admin_role.name
  policy_arn = aws_iam_policy.admin_policy.arn
}

resource "aws_iam_instance_profile" "admin_instance_profile" {
  name = "admin-instance-profile"
  role = aws_iam_role.admin_role.name
}






resource "aws_iam_policy" "worker_policy" {
  name        = "worker_policy"
  description = "Policy for worker nodes to access SSM and EC2 describe instances"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role" "master_role" {
  name               = "master-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "worker_role" {
  name               = "worker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "master_policy_attachment" {
  role       = aws_iam_role.master_role.name
  policy_arn = aws_iam_policy.worker_policy.arn
}

resource "aws_iam_role_policy_attachment" "worker_policy_attachment" {
  role       = aws_iam_role.worker_role.name
  policy_arn = aws_iam_policy.worker_policy.arn
}

resource "aws_iam_instance_profile" "master_instance_profile" {
  name = "master-instance-profile"
  role = aws_iam_role.master_role.name
}

resource "aws_iam_instance_profile" "worker_instance_profile" {
  name = "worker-instance-profile"
  role = aws_iam_role.worker_role.name
}