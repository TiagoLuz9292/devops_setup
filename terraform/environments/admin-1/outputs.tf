output "admin_vpc_id" {
  value = module.admin_vpc.vpc_id
}

output "admin_vpc_cidr" {
  value = module.admin_vpc.vpc_cidr
}

output "admin_instance_id" {
  value = module.admin_instance.instance_id
}

output "admin_instance_public_ip" {
  value = module.admin_instance.instance_public_ip
}

output "route_table_id" {
  value = module.admin_vpc.route_table_id
}