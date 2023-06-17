
data "template_file" "user_data" {
  template = file("html.sh")
}

#EC2 instance creation for Dev
resource "aws_instance" "EC-1" {
  depends_on             = [aws_route_table.main2]
  ami                    = var.AMI_ID
  instance_type          = var.EC2_Size
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  user_data              = data.template_file.user_data.rendered
  iam_instance_profile   = aws_iam_instance_profile.test_profile.name

  tags = {
    Name = "${var.Project}_WebServer"
    Env  = "Private"
  }
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "${var.Project}-EC2-IAM-Profile"
  role = aws_iam_role.role.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "ssmpolicy" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "role" {
  name                = "${var.Project}-SSMRole"
  path                = "/"
  assume_role_policy  = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [data.aws_iam_policy.ssmpolicy.arn]

}