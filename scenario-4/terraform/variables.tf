variable "backup_vault_name" {
  type        = string
  description = "Name of the AWS Backup Vault"
}

variable "backup_plan_name" {
  type        = string
  description = "Name of the AWS Backup Plan"
}

variable "target_region" {
  type        = string
  description = "Region for cross-region backup copy"
}

variable "target_account_id" {
  type        = string
  description = "Account ID for cross-account backup copy"
}

variable "tags_filter" {
  type = map(string)
  default = {
    ToBackup = "true"
    Owner    = "owner@eulerhermes.com.com"
  }
}
