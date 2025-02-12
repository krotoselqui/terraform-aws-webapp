# ランダムなサフィックスの生成
resource "random_id" "suffix" {
  byte_length = 8
}

# S3バケットの作成
resource "aws_s3_bucket" "app_bucket" {
  bucket = "${var.bucket_prefix}-${random_id.suffix.hex}"

  tags = {
    Name = "webapp-bucket"
  }
}

# S3バケットのバージョニング設定
resource "aws_s3_bucket_versioning" "app_bucket_versioning" {
  bucket = aws_s3_bucket.app_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# EC2用のIAMロール
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# S3アクセス用のIAMポリシー
resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app_bucket.arn,
          "${aws_s3_bucket.app_bucket.arn}/*"
        ]
      }
    ]
  })
}

# EC2インスタンスプロファイル
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_s3_profile"
  role = aws_iam_role.ec2_s3_role.name
}

# EC2インスタンス
resource "aws_instance" "web_server" {
  ami           = "ami-03d49b144f3ee2dc4"  # Amazon Linux 2023 AMI (us-west-1用、2025-02-04リリース)
  instance_type = "t2.micro"

  key_name = var.key_pair_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              # Nginxのインストールと起動
              sudo yum update -y
              sudo yum install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx

              # AWS CLIのインストール
              sudo yum install -y aws-cli

              # S3バケットからindex.htmlを取得してnginxのドキュメントルートに配置
              aws s3 cp s3://${aws_s3_bucket.app_bucket.id}/index.html /usr/share/nginx/html/index.html
              aws s3 cp s3://${aws_s3_bucket.app_bucket.id}/calculator.js /usr/share/nginx/html/calculator.js

              # ファイルの権限を設定
              sudo chown nginx:nginx /usr/share/nginx/html/index.html
              sudo chown nginx:nginx /usr/share/nginx/html/calculator.js
              sudo chmod 644 /usr/share/nginx/html/index.html
              sudo chmod 644 /usr/share/nginx/html/calculator.js

              # Nginxの再起動
              sudo systemctl restart nginx
              EOF

  tags = {
    Name = "webapp-server"
  }

  # user_dataが変更された場合にインスタンスを再作成
  user_data_replace_on_change = true
}

# セキュリティグループの設定
resource "aws_security_group" "web_sg" {
  name        = "webapp-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# デフォルトVPCのデータ取得
data "aws_vpc" "default" {
  default = true
}
