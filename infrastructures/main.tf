#------------------------------#
#Create random string
#------------------------------#
resource "random_id" "random" {
  keepers = {
    ami_id = "${var.ami_id}"
  }
  byte_length = 8
}

#------------------------------#
# Configure the AWS Provider
#------------------------------#
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      CostCenter  = "150th"
      Terraform   = "true"
      Environment = "dev"
    }
  }
}

#------------------------------#
#Retrieve the list of AZs in the current AWS region
#------------------------------#
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

#------------------------------#
#Define the VPC
#------------------------------#
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name    = "150th-vpc"
  version = "5.13.0"
  cidr    = var.vpc_cidr

  azs            = tolist(data.aws_availability_zones.available.names)
  public_subnets = [cidrsubnet(var.vpc_cidr, 4, 1)]

}

#------------------------------#
#Build EBS
#------------------------------#
resource "aws_ebs_volume" "server_storage" {
  availability_zone = tolist(data.aws_availability_zones.available.names)[0]
  size              = 100
  type              = "gp3"
  encrypted         = true
  # snapshot_id = 
}

#------------------------------#
#Create EC2 security group
#------------------------------#
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "EC2 security group"
  vpc_id      = module.vpc.vpc_id
}

##Inbound
# resource "aws_vpc_security_group_ingress_rule" "allow_port_9989_from_my_ip" {
#   security_group_id = aws_security_group.ec2_sg.id
#   ip_protocol       = "tcp"
#   from_port         = 9989
#   to_port           = 9989
#   cidr_ipv4         = "YOUR_IP/32" # Replace YOUR_IP with your actual IP address (e.g., 192.168.1.1/32)
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_port_2302_to_2306_tcp" {
#   security_group_id = aws_security_group.ec2_sg.id
#   ip_protocol       = "tcp"
#   from_port         = 2302
#   to_port           = 2306
#   cidr_ipv4         = "0.0.0.0/0"
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_port_2302_to_2306_udp" {
#   security_group_id = aws_security_group.ec2_sg.id
#   ip_protocol       = "udp"
#   from_port         = 2302
#   to_port           = 2306
#   cidr_ipv4         = "0.0.0.0/0"
# }

resource "aws_vpc_security_group_ingress_rule" "allow_all_inbound" {
  security_group_id = aws_security_group.ec2_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

##Outbound
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.ec2_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

#------------------------------#
# IAM Instance Profile for EC2
#------------------------------#
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2_Instance_Profile_SSM"

  role = "EC2_Role_SSM_Connect" # Reference the existing IAM role
}

#------------------------------#
# Render a part using a `template_file`
#------------------------------#
data "template_file" "script" {
  template = file("${path.module}/cloud_config/init.tpl")
  vars = {
    SERVERINIT   = base64encode(file("../server_init.sh"))
    STEAMCMDINIT = base64encode(file("../steamcmd_webpanel_init.sh"))
    SCRIPTINIT   = base64encode(file("../install_mods_and_config.sh"))
    OCAPINIT     = base64encode(file("../install_ocap.sh"))
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.script.rendered
  }
}


#------------------------------#
#Build EC2 instance in Public Subnet
#------------------------------#
module "ec2_instance_dev" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.0"

  name = "arma3-dev-instance"

  instance_type               = "c5.large" # Recommend instances: c5.2xlarge c5.large
  ami                         = var.ami_id
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  subnet_id                   = module.vpc.public_subnets[0]
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  associate_public_ip_address = true
  user_data_base64            = data.template_cloudinit_config.config.rendered
}

# module "ec2_instance_production" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "5.7.0"

#   name = "arma3-test-instance"

#   instance_type               = "m5zn.2xlarge" # Recommend instances: c5.4xlarge m5zn.2xlarge 
#   ami                         = var.ami_id
#   monitoring                  = true
#   vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
#   subnet_id                   = module.vpc.public_subnets[0]
#   iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
#   associate_public_ip_address = true
#   user_data_base64            = data.template_cloudinit_config.config.rendered
# }

#------------------------------#
#Attach volumes to EC2 Instance
#------------------------------#
resource "aws_volume_attachment" "ebs_att_dev" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.server_storage.id
  instance_id = module.ec2_instance_dev.id
}

# resource "aws_volume_attachment" "ebs_att_test" {
#   device_name = "/dev/sdf"
#   volume_id   = aws_ebs_volume.server_storage.id
#   instance_id = module.ec2_instance_production.id
# }
