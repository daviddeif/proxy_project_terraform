variable "vpc_igw" {
  
}
variable "vpc_route" {
  
}
variable "route_name_private" {
  
}
variable "route_name_public" {
  
}

variable "destination_cidr_block" {
  default ="0.0.0.0/0"
}
variable "subnet_id_nat" {
  
}
variable "routepublic" {
  
}
variable "routeprivate" {
  
}
variable "aws_subnet_public" {
  # type = tuple
}
variable "aws_subnet_private" {
  # type = list
}
