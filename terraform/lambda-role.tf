# resource "aws_iam_role" "lambda_role" {
#   name = "lambda-llm-llama-to-endpoint-demo"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#   role       = aws_iam_role.lambda_role.name
# }

# # Custom policy with S3 permissions added
# resource "aws_iam_policy" "custom_lambda_policy" {
#   name        = "lambda-llm-llama-to-endpoint-policy-demo"
#   description = "Policy for lambda-llm-llama-to-endpoint-demo"
#   policy      = data.aws_iam_policy_document.custom_lambda_policy.json
# }

# data "aws_iam_policy_document" "custom_lambda_policy" {
#   statement {
#     actions = [
#       "ecr:DescribeImages",
#       "ecr:DescribeRepositories",
#     ]
#     resources = ["*"]
#   }
#   statement {
#     effect    = "Allow"
#     actions   = [
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:PutLogEvents"
#     ]
#     resources = [
#       "arn:aws:logs:*:*:*"
#     ]
#   }
#   statement {
#     effect    = "Allow"
#     actions   = [
#       "lambda:InvokeFunction",
#       "lambda:InvokeAsync",
#       "lambda:Invoke"
#     ]
#     resources = [
#       "*"
#     ]
#   }
#   statement {
#     effect    = "Allow"
#     actions   = [
#       "kms:*"
#     ]
#     resources = [
#       "*"
#     ]
#   }
#   statement {
#     effect    = "Allow"
#     actions   = [
#       "iam:PassRole"
#     ]
#     resources = [
#       aws_iam_role.lambda_role.arn
#     ]
#   }
#   statement {
#     effect    = "Allow"
#     actions   = [
#       "sagemaker:InvokeEndpoint"
#     ]
#     resources = [
#       "arn:aws:sagemaker:*:*:endpoint/*"
#     ]
#   }
#   statement {
#     effect    = "Allow"
#     actions   = [
#       "ssm:GetParameter"
#     ]
#     resources = [
#       "arn:aws:ssm:*:*:parameter/*"
#     ]
#   }
#   statement {
#     effect = "Allow"
#     actions = [
#       "dynamodb:describeTable",
#       "dynamodb:scan",
#       "dynamodb:query",
#       "dynamodb:getItem",
#       "dynamodb:putItem",
#       "dynamodb:updateItem",
#       "dynamodb:deleteItem",
#       "dynamodb:batchGetItem",
#       "dynamodb:batchWriteItem",
#       "dynamodb:describeLimits",
#       "dynamodb:describeTimeToLive"
#     ]
#     resources = [
#       "arn:aws:dynamodb:*:*:table/*"
#     ]
#   }

# # S3 permissions
# statement {
#   effect = "Allow"
#   actions = [
#     "s3:GetObject",
#     "s3:PutObject",
#     "s3:DeleteObject",
#     "s3:ListBucket"
#   ]
#   resources = [
#     "arn:aws:s3:::qubika-bot",       # Access to the bucket itself
#     "arn:aws:s3:::qubika-bot/*"      # Access to all objects within the bucket
#   ]
# }

# statement {
#    effect = "Allow"
#    actions = [
#      "bedrock:InvokeModel",
#      "bedrock:QueryKnowledgeBase",
#      "bedrock:Retrieve",
#      "bedrock:RetrieveAndGenerate",
#      "bedrock:GetAgent",
#      "bedrock:UpdateAgentAlias",
#      "bedrock:InvokeAgent"
#    ]
#    resources = [
#      "arn:aws:bedrock:*:*:*"
#    ]
#  }

# statement {
#     effect = "Allow"
#     actions = [
#       "sqs:SendMessage",
#       "sqs:GetQueueUrl",
#       "sqs:ReceiveMessage"
#     ]
#     resources = [
#       "arn:aws:sqs:us-east-1:789524919849:qubika_bot_chunks.fifo",
#       "arn:aws:sqs:us-east-1:789524919849:*"
#     ]
#   }
# }

# resource "aws_iam_role_policy_attachment" "custom_policy_attachment" {
#   policy_arn = aws_iam_policy.custom_lambda_policy.arn
#   role       = aws_iam_role.lambda_role.name
# }