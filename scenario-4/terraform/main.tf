resource "aws_kms_key" "backup" {
  description         = "KMS key for backup encryption"
  enable_key_rotation = true
}

resource "aws_backup_vault" "main" {
  name        = var.backup_vault_name
  kms_key_arn = aws_kms_key.backup.arn
  tags        = var.tags_filter
}

resource "aws_backup_vault_lock_configuration" "lock" {
  backup_vault_name   = aws_backup_vault.main.name
  min_retention_days  = 30
  max_retention_days  = 365
  changeable_for_days = 7
}

resource "aws_backup_plan" "main" {
  name = var.backup_plan_name

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 * * ? *)"
    start_window      = 60
    completion_window = 180

    lifecycle {
      delete_after = 90
    }

    copy_action {
      destination_vault_arn = "arn:aws:backup:${var.target_region}:${var.target_account_id}:backup-vault/${var.backup_vault_name}"
      lifecycle {
        delete_after = 90
      }
    }
  }
}

resource "aws_backup_selection" "by_tag" {
  name           = "tag-selection"
  iam_role_arn   = aws_iam_role.backup.arn
  backup_plan_id = aws_backup_plan.main.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "ToBackup"
    value = "true"
  }

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Owner"
    value = "owner@eulerhermes.com.com"
  }
}

resource "aws_iam_role" "backup" {
  name = "AWSBackupDefaultServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "backup.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}
