variable "vpc_id" {}
variable "subnet_ids" {}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.10.0"
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "Test_Lambda_Function_Role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }]
  })
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name = "aws_iam_policy_for_terraform_aws_lambda_role"
  path = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
    {
       "Action": [
         "logs:CreateLogGroup",
         "logs:CreateLogStream",
         "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role = aws_iam_role.lambda_role.name
  policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "zip_the_python_code" {
  type = "zip"
  source_dir  = "${path.module}/src/"
  output_path = "${path.module}/src/hello.zip"
}

resource "aws_lambda_function" "terraform_lambda_func" {
  filename = "${path.module}/src/hello.zip"
  function_name = "Test_Lambda_Function"
  role = aws_iam_role.lambda_role.arn
  handler = "index.lambda_handler"
  runtime = "python3.8"
  depends_on = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  
  vpc_config {
    # Every subnet should be able to reach an EFS mount target in the same Availability Zone. Cross-AZ mounts are not permitted.
    subnet_ids         = [var.subnet_ids]
    security_group_ids = [var.vpc_id]
  }
}
