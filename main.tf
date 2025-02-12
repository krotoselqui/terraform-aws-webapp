resource "aws_instance" "web_server" {
  ami           = "ami-0b2c21a346f6d9ef6"  # Amazon Linux 2 (us-west-1用)
  instance_type = "t2.micro"

  key_name = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              echo "Hello, World!" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "webapp-server"
  }
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
