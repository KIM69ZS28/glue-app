# --- 1. SSM 用 VPC エンドポイント (3 つ必要) ---
# これにより NAT Gateway なしで SSM 通信を可能にします
locals {
  ssm_services = ["ssm", "ssmmessages", "ec2messages"]
}

resource "aws_vpc_endpoint" "ssm_endpoints" {
  for_each            = toset(local.ssm_services)
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id]
  security_group_ids  = [aws_security_group.rds_sg.id]
  private_dns_enabled = true

  tags = { Name = "${var.project_name}-${each.value}-endpoint" }
}

# --- 2. 診断用 EC2 インスタンスの権限 (IAM) ---
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# --- 3. 診断用 EC2 インスタンス本体 ---
resource "aws_instance" "diag_server" {
  ami                    = "ami-0d52744d6551d851e" # Amazon Linux 2023 (ap-northeast-1)
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_a.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = { Name = "${var.project_name}-diag-server" }
}