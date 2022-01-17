# TODO: Review ownership/access policies https://aws.amazon.com/about-aws/whats-new/2021/11/amazon-s3-object-ownership-simplify-access-management-data-s3/
resource "aws_s3_bucket" "config" {
  bucket = "terraria.nicholas.cloud"
  force_destroy = true
}

resource "aws_efs_file_system" "worlds" {
  availability_zone_name = aws_subnet.main.availability_zone

  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
}

resource "aws_efs_backup_policy" "worlds" {
  file_system_id = aws_efs_file_system.worlds.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_efs_mount_target" "worlds" {
  file_system_id  = aws_efs_file_system.worlds.id
  subnet_id       = aws_subnet.main.id
  security_groups = [aws_default_security_group.main.id]
}

resource "aws_datasync_task" "backup" {
  name                     = "terrarium-backup"
  source_location_arn      = aws_datasync_location_efs.worlds.arn
  destination_location_arn = aws_datasync_location_s3.config.arn

  schedule {
    schedule_expression = "cron(0 0 * * ? *)"
  }
}

resource "aws_datasync_location_efs" "worlds" {
  efs_file_system_arn = aws_efs_file_system.worlds.arn

  ec2_config {
    security_group_arns = [aws_default_security_group.main.arn]
    subnet_arn          = aws_subnet.main.arn
  }

  depends_on = [aws_efs_mount_target.worlds]
}

resource "aws_datasync_location_s3" "config" {
  s3_bucket_arn = aws_s3_bucket.config.arn
  subdirectory  = "/worlds/"
  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync.arn
  }

  depends_on = [aws_iam_role_policy_attachment.write_storage_bucket]
}

resource "aws_iam_role" "datasync" {
  name               = "TerrariaDatasyncRole"
  assume_role_policy = data.aws_iam_policy_document.datasync_assume_role.json
}

data "aws_iam_policy_document" "datasync_assume_role" {
  version = "2012-10-17"
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "write_storage_bucket" {
  role       = aws_iam_role.datasync.name
  policy_arn = aws_iam_policy.write_storage_bucket.arn
}

resource "aws_iam_policy" "write_storage_bucket" {
  policy = data.aws_iam_policy_document.write_storage_bucket.json
}

data "aws_iam_policy_document" "write_storage_bucket" {
  version = "2012-10-17"
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [aws_s3_bucket.config.arn]
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.config.arn}/*"]
  }
}
