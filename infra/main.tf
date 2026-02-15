provider "aws" {
  region = var.aws_region
}

# --- 1. VPCの作成 ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# --- 2. プライベートサブネットの作成 (2AZ分) ---
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.project_name}-private-a"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${var.project_name}-private-c"
  }
}

# --- 3. RDS用サブネットグループ ---
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_c.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# --- 4. セキュリティグループ (PostgreSQL用) ---
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow inbound traffic from Glue (Self-reference)"
  vpc_id      = aws_vpc.main.id

  # 1. 同一SG間でのRDS通信を許可
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1" # すべてのプロトコル
    self      = true # 同じSGを持つもの同士は何でもOK
  }

  # # 2. 同一SG間（EC2とSSMエンドポイント間）でのHTTPS通信を許可 
  # ingress {
  #   from_port = 443
  #   to_port   = 443
  #   protocol  = "tcp"
  #   self      = true
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# --- 5. RDS PostgreSQL インスタンス (Gold層) ---
resource "aws_db_instance" "gold_db" {
  identifier             = "glue-app-db"
  allocated_storage      = 20 # 無料枠の上限(20GB)に設定
  max_allocated_storage  = 20 # 自動拡張による予期せぬ課金を防止
  engine                 = "postgres"
  engine_version         = "16.6"
  instance_class         = var.db_instance_class # variables.tfでdb.t3.microを指定
  db_name                = "gold_db"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # 運用・コスト設定
  multi_az                  = false # 無料枠を維持するためSingle-AZ
  publicly_accessible       = false # 外部からの接続を遮断
  skip_final_snapshot       = false # 削除時にスナップショットを残す
  final_snapshot_identifier = "${var.project_name}-final-snapshot"

  tags = {
    Name = "${var.project_name}-rds"
  }
}

# --- 6. ルートテーブルの設定 ---
# サブネットが「S3への行き方」を知るための地図を作成します
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# サブネット A をルートテーブルに紐付け
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# サブネット C をルートテーブルに紐付け
resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private.id
}

# --- 7. S3 ゲートウェイエンドポイント ---
# 構成図 ⑤ に該当：NAT Gateway（有料）を使わずにS3と通信するための専用路です
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  # 作成したルートテーブルに、S3行きのルートを自動的に書き込みます
  route_table_ids = [aws_route_table.private.id]

  tags = {
    Name = "${var.project_name}-s3-gw"
  }
}