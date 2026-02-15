# --- 1. Glue Connection (VPC内RDSへの接続路) ---
resource "aws_glue_connection" "rds_connection" {
  name = "${var.project_name}-connection"

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:postgresql://${aws_db_instance.gold_db.endpoint}/${aws_db_instance.gold_db.db_name}"
    USERNAME            = var.db_username
    PASSWORD            = var.db_password
  }

  physical_connection_requirements {
    availability_zone      = aws_subnet.private_c.availability_zone
    security_group_id_list = [aws_security_group.rds_sg.id]
    subnet_id              = aws_subnet.private_c.id
  }
}

# --- 2. スクリプト保存用バケットへのアップロード ---
# GlueはS3上にスクリプトが置かれていないと実行できないため、自動で転送します
resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.gold.id # スクリプトはGold(管理用)バケットに保管
  key    = "scripts/etl_job.py"
  source = "${path.module}/../scripts/etl_job.py"
  etag   = filemd5("${path.module}/../scripts/etl_job.py")
}

# --- 3. Glue ジョブ本体 ---
resource "aws_glue_job" "etl_job" {
  name         = "${var.project_name}-etl-job"
  role_arn     = aws_iam_role.glue_service_role.arn
  glue_version = "4.0" # Spark 3.3 環境

  command {
    script_location = "s3://${aws_s3_bucket.gold.id}/${aws_s3_object.glue_script.key}"
    python_version  = "3"
  }

  connections = [aws_glue_connection.rds_connection.name]

  default_arguments = {
    "--job-language"                     = "python"
    "--continuous-log-logGroup"          = "/aws-glue/jobs/${var.project_name}"
    "--enable-continuous-cloudwatch-log" = "true"
  }
}
