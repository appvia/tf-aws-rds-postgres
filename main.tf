provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_security_group" "rds_postgres_sg" {
  name        = "inbound_to_aws_rds_${var.identifier}"
  description = "Allow inbound traffic to RDS Instance ${var.identifier}"
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = var.sg_ingress_cidr_blocks
  }

  tags = var.tags
}

data "aws_iam_policy_document" "cloudwatch_log_group_kms_access" {
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid     = "Enable CloudWatch Log Group Access"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]

    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"

      values = [
        "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/rds/instance/${var.identifier}/postgresql",
        "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/rds/instance/${var.identifier}/upgrade",
      ]
    }
  }
}

resource "aws_kms_key" "rds_postgres_key" {
  description         = "KMS Key for RDS Instance: ${var.identifier}"
  enable_key_rotation = true
  multi_region        = false
  policy              = data.aws_iam_policy_document.cloudwatch_log_group_kms_access.json
  tags                = var.tags
}

module "rds_postgres_db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "4.2.0"

  identifier = var.identifier

  engine                      = "postgres"
  engine_version              = var.engine_version
  family                      = var.family
  major_engine_version        = var.major_engine_version
  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  instance_class              = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.iops

  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds_postgres_key.arn

  db_name                = var.db_name
  username               = var.username
  password               = var.password
  create_random_password = var.create_random_password
  random_password_length = 16

  port = var.port

  multi_az               = var.multi_az
  create_db_subnet_group = true
  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = ["${aws_security_group.rds_postgres_sg.id}"]

  maintenance_window                     = var.maintenance_window
  backup_window                          = var.backup_window
  enabled_cloudwatch_logs_exports        = ["postgresql", "upgrade"]
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = aws_kms_key.rds_postgres_key.arn

  backup_retention_period          = var.backup_retention_period
  snapshot_identifier              = var.snapshot_identifier
  skip_final_snapshot              = var.skip_final_snapshot
  copy_tags_to_snapshot            = true
  final_snapshot_identifier_prefix = "final"
  deletion_protection              = var.deletion_protection
  delete_automated_backups         = var.delete_automated_backups
  apply_immediately                = var.apply_immediately

  create_monitoring_role      = true
  monitoring_interval         = var.monitoring_interval
  monitoring_role_name        = "rds-${var.region}-${var.identifier}-monitoring-role"
  monitoring_role_description = "IAM Role for monitoring RDS Instance: ${var.identifier}"

  parameters = concat([
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ], var.parameters)

  tags = var.tags
}
