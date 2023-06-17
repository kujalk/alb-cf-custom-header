/*
Purpose - To create an EC2 instance with VPC (Public Subnet) with Security Group attached
Developer - K.Janarthanan
*/

#Security Group for EC2
resource "aws_security_group" "ec2" {
  name        = "${var.Project}-EC2-SG"
  description = "To allow HTTP Traffic from ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.Project}-EC2-SG"
  }

  ingress {
    description     = "HTTP Traffic Allow"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Outside"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Security Group for LB
resource "aws_security_group" "alb" {
  name        = "${var.Project}-ALB-SG"
  description = "To allow HTTP and SSH Traffic"
  vpc_id      = aws_vpc.main.id


  tags = {
    Name = "${var.Project}-ALB-SG"
  }

  ingress {
    description = "HTTP Traffic Allow"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outside"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}