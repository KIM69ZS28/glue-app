# --- プロジェクト基本設定 ---
variable "project_name" {
  description = "リソースの命名やタグ付けに使用するプロジェクト識別名"
  type        = string
  default     = "glue-app"
}

variable "aws_region" {
  description = "リソースをデプロイするAWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

# --- ネットワーク設定 ---
variable "vpc_cidr" {
  description = "VPC全体に割り当てるIPアドレスの範囲（CIDRブロック）"
  type        = string
  default     = "10.0.0.0/16"
}

# --- データベース設定 ---
variable "db_username" {
  description = "RDS PostgreSQLインスタンスのマスターユーザー名"
  type        = string
  default     = "postgres_admin"
}

variable "db_password" {
  description = "RDS PostgreSQLインスタンスのマスターパスワード"
  type        = string
  sensitive   = true # 実行ログに表示されないよう保護
}

variable "db_instance_class" {
  description = "RDSのインスタンスタイプ（無料枠適用のためのdb.t3.micro）"
  type        = string
  default     = "db.t3.micro"
}