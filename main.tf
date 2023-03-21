provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["~/Desktop/mycredentials"]
  profile                  = "default"
}
module "main_vpc" {
  source = "./vpc"
  cidr = "10.0.0.0/16"
  vpc_name = "david"
}
module "public_subnet1" {
  source = "./subnets"
  vpc_id = module.main_vpc.vpc_id
  cidr_subnet = "10.0.0.0/24"
  availabilityzone = "us-east-1a"
  subnet_name = "public_subnet1"
}
module "public_subnet2" {
  source = "./subnets"
  vpc_id = module.main_vpc.vpc_id
  cidr_subnet = "10.0.2.0/24"
  availabilityzone = "us-east-1b"
  subnet_name = "public_subnet2"
}
module "private_subnet1" {
  source = "./subnets"
  vpc_id = module.main_vpc.vpc_id
  cidr_subnet = "10.0.1.0/24"
  availabilityzone = "us-east-1a"
  subnet_name = "private_subnet1"
}
module "private_subnet2" {
  source = "./subnets"
  vpc_id = module.main_vpc.vpc_id
  cidr_subnet = "10.0.4.0/24"
  availabilityzone = "us-east-1b"
  subnet_name = "private_subnet2"
}

module "networking" {
  source = "./routing"
  vpc_igw = module.main_vpc.vpc_id
  vpc_route = module.main_vpc.vpc_id
  route_name_private  = "private-route-table"
  route_name_public = "public-route-table"
  subnet_id_nat =  module.public_subnet2.subnet_id
  routepublic = module.networking.route_table_publicc
  routeprivate = module.networking.route_table_privatee
  aws_subnet_public = { a = module.public_subnet1.subnet_id , b =  module.public_subnet2.subnet_id }
  
  aws_subnet_private = { a = module.private_subnet1.subnet_id , b =  module.private_subnet2.subnet_id }
  
}
module "security_group" {
  source = "./securitygroup"
  secgr_name = "security_group"
  secgr_description = "security_group"
  secgr_vpc_id = module.main_vpc.vpc_id
  secgr_from_port_in = 22
  secgr_to_port_in = 80
  secgr_protocol_in = "tcp"
  secgr_cider = ["0.0.0.0/0"]
  secgr_from_port_eg = 0
  secgr_to_port_eg = 0
  secgr_protocol_eg = "-1"
}
module "ec2_public1" {
  source = "./public_ec2"
  ec2_ami_id = "ami-06878d265978313ca"
  ec2_instance_type = "t2.micro"
  ec2_name = "ec2_public_01"
  ec2_public_ip = true
  ec2_subnet_ip = module.public_subnet1.subnet_id
  ec2_security_gr = [ module.security_group.secgr_id ]
  ec2_key_name = "iti"
  ec2_connection_type = "ssh"
  ec2_connection_user = "ubuntu"
  ec2_connection_private_key = "/home/david/Desktop/iti.pem"
  ec2_provisioner_file_source = "./nginx.sh"
  ec2_provisioner_file_destination = "/tmp/nginx.sh"
  ec2_provisioner_inline = [ "chmod 777 /tmp/nginx.sh", "/tmp/nginx.sh ${module.lb_private.lb_public_dns}" ]
  depends_on = [
    module.public_subnet1.subnet_id,
    module.lb_private.lb_public_dns
  ]
}

module "ec2_public2" {
  source = "./public_ec2"
  ec2_ami_id = "ami-06878d265978313ca"
  ec2_instance_type = "t2.micro"
  ec2_name = "ec2_public_02"
  ec2_public_ip = true
  ec2_subnet_ip = module.public_subnet2.subnet_id
  ec2_security_gr = [ module.security_group.secgr_id ]
  ec2_key_name = "iti"
  ec2_connection_type = "ssh"
  ec2_connection_user = "ubuntu"
  ec2_connection_private_key = "/home/david/Desktop/iti.pem"
  ec2_provisioner_file_source = "./nginx.sh"
  ec2_provisioner_file_destination = "/tmp/nginx.sh"
  ec2_provisioner_inline = [ "chmod 777 /tmp/nginx.sh", "/tmp/nginx.sh ${module.lb_private.lb_public_dns}" ]
  depends_on = [
    module.public_subnet2.subnet_id,
    module.lb_private.lb_public_dns
  ]
}

module "lb_public" {
  source = "./loadbalancer"

  target_name = "public"
  target_port = "80"
  target_protocol = "HTTP"
  target_vpc_id = module.main_vpc.vpc_id

  attach_target_id = { id1 = module.ec2_public1.ec2_id, id2 = module.ec2_public2.ec2_id }
  attach_target_port = "80"

  lb_name = "public"
  lb_internal = false
  lb_type = "application"
  lb_security_group = [ module.security_group.secgr_id ]
  lb_subnet = [ module.public_subnet1, module.public_subnet2 ]

  listener_port = "80"
  listener_protocol = "HTTP"
  listener_type = "forward"

  depends_on = [
    module.main_vpc,
    module.ec2_public1,
    module.ec2_public2,
    module.public_subnet1,
    module.public_subnet2
  ]

}
module "ec2_private1" {
  source = "./private_ec2"
  ec2_ami_id = "ami-06878d265978313ca"
  ec2_instance_type = "t2.micro"
  ec2_name = "ec2_private_01"
  ec2_subnet_ip = module.private_subnet1.subnet_id
  ec2_security_gr = [ module.security_group.secgr_id ]
  ec2_key_name = "iti"
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx
    sudo chmod 777 /var/www/html
    sudo chmod 777 /var/www/html/index.nginx-debian.html
    sudo echo "<h1>Hello World! - David private EC2 01</h1>" > /var/www/html/index.nginx-debian.html
    sudo systemctl restart nginx
  EOF
}

module "ec2_private2" {
  source = "./private_ec2"
  ec2_ami_id = "ami-06878d265978313ca"
  ec2_instance_type = "t2.micro"
  ec2_name = "ec2_private_02"
  ec2_subnet_ip = module.private_subnet2.subnet_id
  ec2_security_gr = [ module.security_group.secgr_id ]
  ec2_key_name = "iti"
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx
    sudo chmod 777 /var/www/html
    sudo chmod 777 /var/www/html/index.nginx-debian.html
    sudo echo "<h1>Hello World! - David  private EC2 02</h1>" > /var/www/html/index.nginx-debian.html
    sudo systemctl restart nginx
  EOF
}





module "lb_private" {
  source = "./loadbalancer"

  target_name = "private"
  target_port = "80"
  target_protocol = "HTTP"
  target_vpc_id = module.main_vpc.vpc_id

  attach_target_id = { id1 = module.ec2_private1.ec2_id, id2 = module.ec2_private2.ec2_id }
  attach_target_port = "80"

  lb_name = "private"
  lb_internal = true
  lb_type = "application"
  lb_security_group = [ module.security_group.secgr_id ]
  lb_subnet = [ module.private_subnet1, module.private_subnet2 ]

  listener_port = "80"
  listener_protocol = "HTTP"
  listener_type = "forward"

  depends_on = [
    module.main_vpc,
    module.ec2_private1,
    module.ec2_private2,
    module.private_subnet1,
    module.private_subnet2
  ]

}
