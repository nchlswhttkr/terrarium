# TODO: Force delete objects on destroy
# TODO: Review ownership/access policies https://aws.amazon.com/about-aws/whats-new/2021/11/amazon-s3-object-ownership-simplify-access-management-data-s3/
resource "aws_s3_bucket" "config" {
  bucket = "terraria.nicholas.cloud"
}

resource "aws_s3_bucket_policy" "preview_bucket_policy" {
  bucket = aws_s3_bucket.config.bucket
  policy = data.aws_iam_policy_document.public_bucket_access.json
}

data "aws_iam_policy_document" "public_bucket_access" {
  version = "2012-10-17"
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.config.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

# TODO: Set up DataSync
resource "aws_efs_file_system" "worlds" {
  availability_zone_name = aws_subnet.main.availability_zone

  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
}

resource "aws_efs_mount_target" "worlds" {
  file_system_id  = aws_efs_file_system.worlds.id
  subnet_id       = aws_subnet.main.id
  security_groups = [aws_default_security_group.main.id]
}
