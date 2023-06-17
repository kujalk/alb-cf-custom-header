
resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.Project}-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["lambda.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "${var.Project}-lambda-policy"
  path        = "/"
  description = "${var.Project} lambda policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*"
            ]
        },
        {
            "Action": [
                "cloudfront:*"
            ],
            "Effect": "Allow",
            "Resource": "${aws_cloudfront_distribution.alb_distribution.arn}"
        },
         {
            "Action": [
                "secretsmanager:*"
            ],
            "Effect": "Allow",
            "Resource": "${aws_secretsmanager_secret.header.arn}"
        },
        {
            "Effect": "Allow",
            "Action": "elasticloadbalancing:*",
            "Resource": [
            "${aws_lb.alb.arn}",
            "${aws_lb_listener_rule.static.arn}",
            "${aws_lb_listener.front_end.arn}",
            "${aws_lb_target_group.test.arn}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}