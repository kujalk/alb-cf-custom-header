#create secretmanger with random string

resource "random_string" "secret" {
  length  = 6
  special = false
  upper   = false
  lower   = true
}

resource "aws_secretsmanager_secret" "header" {
  name = "${var.Project}-secret-${random_string.secret.result}"
}

resource "aws_secretsmanager_secret_version" "header" {
  secret_id     = aws_secretsmanager_secret.header.id
  secret_string = random_string.header.result
}