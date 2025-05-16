
resource "aws_kms_key" "backup_key" {
  description = "KMS key for backup vault encryption"
}

resource "aws_backup_vault" "vault" {
  name          = var.name
  kms_key_arn   = aws_kms_key.backup_key.arn
  force_destroy = var.force_destroy
}

resource "aws_backup_plan" "plan" {
  name = var.name

  rule {
    rule_name         = var.name
    target_vault_name = aws_backup_vault.vault.name
    schedule          = var.schedule
    lifecycle {
      delete_after = var.backup_retention
    }
  }
}

resource "aws_backup_selection" "selection" {
  iam_role_arn = var.iam_role_arn
  name         = var.name
  plan_id      = aws_backup_plan.plan.id

  resources = [
    var.instance_arn
  ]
}
