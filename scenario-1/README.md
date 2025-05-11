# Scenario 1 –  Encryption management Key rotation on AWS

##  1. What are the main challenges to apply key rotation? What impacts you can identify?

### Main Challenges

- Manual rotation: BYOK keys do not support automatic rotation. You must manually import new key material.
- Service disruption risk: Updating keys without downtime requires coordination and precise service updates.
- Data re-encryption: May be required after key rotation and is resource-intensive.
- Alias and dependency management: Aliases must be updated properly and all dependent services reconfigured.
- IAM and key policy adjustments: Policies must be revised with every key rotation to maintain least privilege.
- Audit traceability: Maintaining a consistent log trail across key versions.

### Potential Impacts

- Service failures if services continue to use the old key.
- Increased attack surface if old key remains active too long.
- Compliance violations if key rotation is incomplete or incorrectly executed.
- High operational effort without automation.

## 2. From your respective, what are the steps of applying key rotation (high level description)

1. Generate new key material securely from your on-prem HSM.
2. Download import token and KMS public key** from AWS KMS console or API.
3. Wrap the new key material using the public key with RSAES-OAEP-SHA256.
4. Import the new key material into the existing CMK or into a new CMK.
5. Update key alias (if a new CMK is created) to ensure seamless service continuity.
6. Update encryption configurations in services (S3, RDS, DynamoDB, etc.).
7. Re-encrypt existing data, if business or compliance policies require it.
8. Validate logs and access through AWS CloudTrail.
9. Disable and retire the old key material after a transition period.

## 3. After applying the rotation on keys, we’re required to have a monitoring on the resources to identify - at any given time - resources (rds, dynamodb, S3) that are not complaints (resources where rotation is not applied) how could we achieve this requirement with AN aws managed services?

**AWS Config**
- Enable managed rules:
  - `s3-bucket-server-side-encryption-enabled`
  - `rds-storage-encrypted`
  - `dynamodb-table-encryption-enabled`
- Add a custom AWS Config rule with Lambda to:
  - Inspect KMS key IDs or aliases of encrypted resources.
  - Mark resources using outdated keys as non-compliant.

**AWS Security Hub**
- Integrate with AWS Config for a centralized security dashboard.
- Visualize resource compliance across services and accounts.

**Amazon EventBridge + CloudWatch**
- Set alarms or triggers for key rotation compliance checks.
- Automate remediation workflows (e.g. tag non-compliant resources, alert teams).

## 4. What’s the best way to secure key material during their transportation from HSM to AWS KMS? 

1. Use KMS’s secure import mechanism:
   - Download the import token and public key from the KMS key configuration.
   - Encrypt key material using RSAES-OAEP-SHA256.

2. Perform key wrapping on a secure, isolated host:
   - Ideally, use an air-gapped or dedicated security workstation.
   - Do not store unencrypted key material.

3. Upload wrapped key material via AWS CLI or SDK:
   - Use a hardened machine and temporary IAM credentials with least privilege.
   - Log the import action with CloudTrail.

4. Apply expiration & usage constraints:
   - Use key expiration policies and lifecycle controls.
   - Implement `EnableKeyRotation` where possible for symmetric keys.

5. Log and audit everything:
   - CloudTrail + AWS Config + manual attestation from key custodians.