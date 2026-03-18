# Create an AWS Organizations Org in the Master Account
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
  ]

  feature_set = "ALL"
}

# Create the Audit Account

resource "aws_organizations_account" "audit" {
  depends_on = [ aws_organizations_organization.org ]
  name  = "${var.audit_account_friendlyname}"
  email = "${var.audit_account_email}"
  close_on_deletion = "${var.audit_close_on_delete}"
}

# Create the Logging Account

resource "aws_organizations_account" "logging" {
  depends_on = [ aws_organizations_organization.org ]
  name  = "${var.logging_account_friendlyname}"
  email = "${var.logging_account_email}"
  close_on_deletion = "${var.logging_close_on_delete}"
}

resource "aws_controltower_landing_zone" "example" {
  depends_on = [
    aws_organizations_account.audit,
    aws_organizations_account.logging
  ]

  version = "4.0"

  manifest_json = jsonencode({
    governedRegions = var.governed_regions

    centralizedLogging = {
      accountId = aws_organizations_account.logging.id
      enabled   = true
      configurations = {
        loggingBucket = {
          retentionDays = 60
        }
        accessLoggingBucket = {
          retentionDays = 60
        }
      }
    }

    config = {
      accountId = aws_organizations_account.audit.id
      enabled   = true
      configurations = {
        loggingBucket = {
          retentionDays = 60
        }
        accessLoggingBucket = {
          retentionDays = 60
        }
      }
    }

    securityRoles = {
      accountId = aws_organizations_account.audit.id
      enabled   = true
    }

    accessManagement = {
      enabled = true
    }

    backup = {
      enabled = false
    }
  })
}
