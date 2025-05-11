# Scenario 4 – Backup Policy Laveraging AWS Backup

A reusable Terraform module is provided under the `terraform/` folder that provisions:
- A backup vault with optional KMS encryption and Vault Lock enabled
- A backup plan with lifecycle rules and cross-region + cross-account copy
- A backup selection policy using resource tags
- Required IAM roles and policies

## Usage Example

module "aws_backup" {
  source              = "./scenario-4-backup-module/terraform"
  backup_vault_name   = "central-backup-vault"
  backup_plan_name    = "daily-backup-plan"
  target_region       = "eu-west-1"
  target_account_id   = "123456789012"
}