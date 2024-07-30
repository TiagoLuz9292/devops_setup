output "master_public_ip" {
  value = module.k8s_cluster.master_public_ip
}

output "asg_name" {
  value = module.k8s_cluster.asg_name
}

output "scale_out_policy_arn" {
  value = module.k8s_cluster.scale_out_policy_arn
}

output "scale_in_policy_arn" {
  value = module.k8s_cluster.scale_in_policy_arn
}
