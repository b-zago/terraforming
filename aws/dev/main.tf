module "vpc" {
  source   = "../modules/vpc/"
  vpc_name = "dev"
  cidr     = "10.0.0.0/16"
  public_subnets = {
    "public-1" : {
      "cidr" : "10.0.0.0/24"
      "az" : "eu-central-1a"
    }
  }
}


resource "aws_key_pair" "dev" {
  key_name   = "dev"
  public_key = file("~/.ssh/id_dev.pub")
}

resource "aws_security_group" "ssh" {
  name   = local.name
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.dev_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = [var.dev_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "dev_ip" {
  domain = "vpc"

  depends_on = [module.vpc]
}

# resource "aws_eip_association" "dev" {
#   instance_id   = aws_instance.dev.id
#   allocation_id = aws_eip.dev_ip.id
# }
#
# resource "aws_instance" "dev" {
#   ami                    = "ami-0b8f1aedf379c35ee"
#   instance_type          = "m8i.xlarge"
#   subnet_id              = module.vpc.public_subnet_ids["public-1"]
#   vpc_security_group_ids = [aws_security_group.ssh.id]
#   key_name               = aws_key_pair.dev.key_name
#
#   source_dest_check = false
#
#   cpu_options {
#     nested_virtualization = "enabled"
#   }
#
#   user_data = <<-EOF
#     #cloud-config
#     hostname: pve
#   EOF
# }
#
# resource "aws_ebs_volume" "thin-pool" {
#   availability_zone = "eu-central-1a"
#   size              = 40
#   type              = "gp3"
#
# }
#
# resource "aws_volume_attachment" "thin-pool" {
#   device_name = "/dev/sdf"
#   volume_id   = aws_ebs_volume.thin-pool.id
#   instance_id = aws_instance.dev.id
#
# }

