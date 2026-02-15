# --- 1. Glueサービス用のIAMロール ---
# GlueがAWSの他のサービス（S3やRDS）を操作するための「身分証」です
resource "aws_iam_role" "glue_service_role" {
  name = "${var.project_name}-glue-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}

# --- 2. AWS管理ポリシーのアタッチ ---
# Glueの基本操作に必要な権限（ログ出力など）を付与します
resource "aws_iam_role_policy_attachment" "glue_base_policy" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# --- 3. 特定のS3バケットへのアクセスポリシー ---
# 先ほど作成したBronze/Silver/Goldバケットのみを操作できる権限です
resource "aws_iam_policy" "glue_s3_access" {
  name        = "${var.project_name}-glue-s3-access-policy"
  description = "Allow Glue to access project S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.bronze.arn,
          "${aws_s3_bucket.bronze.arn}/*",
          aws_s3_bucket.silver.arn,
          "${aws_s3_bucket.silver.arn}/*",
          aws_s3_bucket.gold.arn,
          "${aws_s3_bucket.gold.arn}/*"
        ]
      }
    ]
  })
}

# --- 4. S3アクセスポリシーのロールへのアタッチ ---
resource "aws_iam_role_policy_attachment" "glue_s3_access_attach" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_s3_access.arn
}