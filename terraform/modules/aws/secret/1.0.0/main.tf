
resource "aws_secretsmanager_secret" "secret" {
  name                    = var.secret_name
  description             = var.secret_description
  recovery_window_in_days = var.recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = var.secret_string
  depends_on    = [aws_secretsmanager_secret.secret]
}
