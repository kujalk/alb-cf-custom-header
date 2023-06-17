resource "aws_lambda_function" "lambda" {
  filename         = "myFunction.zip"
  function_name    = "${var.Project}-lambda"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda" //name of the go executable 
  publish          = true
  source_code_hash = filebase64sha256("myFunction.zip")
  runtime          = "go1.x"
  timeout          = 180

  environment {
    variables = {
      DISTRIBUTION_ID   = aws_cloudfront_distribution.alb_distribution.id
      HEADER_NAME       = var.Header_Value
      AWS_SECRET_ID     = aws_secretsmanager_secret.header.name
      TARGET_GROUP_ARN  = aws_lb_target_group.test.arn
      LISTENER_RULE_ARN = aws_lb_listener_rule.static.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs
  ]
}
