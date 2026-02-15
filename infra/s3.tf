# --- 1. S3 Buckets (Medallion Architecture) ---

# Bronze層: 生データ（CSVなど）をそのまま置く場所
resource "aws_s3_bucket" "bronze" {
  bucket        = "${var.project_name}-bronze-${var.aws_region}"
  force_destroy = true # 開発用：中身があってもTerraformで削除可能にする
}

# Silver層: 加工・クレンジング済みのデータを置く場所
resource "aws_s3_bucket" "silver" {
  bucket        = "${var.project_name}-silver-${var.aws_region}"
  force_destroy = true
}

# Gold層: 最終的に集計したデータ（Parquet等）を置く場所
resource "aws_s3_bucket" "gold" {
  bucket        = "${var.project_name}-gold-${var.aws_region}"
  force_destroy = true
}

# --- 2. S3 Public Access Block ---
# すべてのバケットに対してパブリックアクセスを厳格に禁止します

resource "aws_s3_bucket_public_access_block" "bronze_block" {
  bucket = aws_s3_bucket.bronze.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "silver_block" {
  bucket = aws_s3_bucket.silver.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "gold_block" {
  bucket = aws_s3_bucket.gold.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
