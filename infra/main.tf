resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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

resource "aws_iam_policy" "iam_policy_for_resume_project" {

  name        = "aws_iam_policy_for_terraform_resume_project_policy"
  path        = "/"
  description = "AWS IAM Policy for managing the resume project role"
    policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:*",
          "Effect" : "Allow"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:UpdateItem",
			      "dynamodb:GetItem"
          ],
          "Resource" : "arn:aws:dynamodb:*:*:table/cloudresume-test"
        },
      ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.iam_policy_for_resume_project.arn
  
}



data "archive_file" "zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/"
  output_path = "${path.module}/lambda/func.zip"
}

resource "aws_lambda_function_url" "url1" {
  function_name       = aws_lambda_function.myfunc.function_name
  authorization_type  = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }

}

resource "aws_lambda_function" "myfunc" {
  filename          = data.archive_file.zip.output_path
  source_code_hash  = data.archive_file.zip.output_base64sha256
  function_name     = "myfunc"
  role              = aws_iam_role.iam_for_lambda.arn
  handler           = "myfunc.lambda_handler"
  runtime           = "python3.8"
  depends_on        = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

resource "aws_dynamodb_table" "cloudresume-test" {
  name         = "cloudresume-test"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }


  tags = {
    Name        = "project"
    Environment = "Cloud Resume Challenge"
    project     = "Cloud Resume Challenge"
  }

  lifecycle {
    
    create_before_destroy = true
  }
}

resource "aws_dynamodb_table_item" "views_counter_item" {
  table_name = aws_dynamodb_table.cloudresume-test.name
  hash_key   = aws_dynamodb_table.cloudresume-test.hash_key

  item = <<ITEM
{
  "id": {"S": "1"},
  "views": {"N": "191"}
}
ITEM

  
#   item = <<ITEM
# {
#   "id": {"S": "1"},
#   "views": {"N": "191"}
# }
# ITEM
  # action = "update"
  lifecycle {
    ignore_changes = [item]
  }
}