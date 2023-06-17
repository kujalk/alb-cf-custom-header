resource "aws_cloudwatch_event_rule" "every_one_day" {
  name                = "${var.Project}-trigger-lambda"
  description         = "${var.Project} to trigger lambda function"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.every_one_day.name
  target_id = "${var.Project}-lambda"
  arn       = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call" {
  statement_id  = "${var.Project}AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_one_day.arn
}