
output "secret_id" {
  description = "The ID of the created secret."
  value       = aws_secretsmanager_secret.secret.id
}

output "secret_arn" {
  description = "The ARN of the created secret."
  value       = aws_secretsmanager_secret.secret.arn
}
