module "vpc" {
  source = "../../module/vpc"
    name = var.name
    cidr = var.cidr

}