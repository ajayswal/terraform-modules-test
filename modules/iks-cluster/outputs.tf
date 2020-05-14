# cluster config file path
output "cluster_config_file_path" {
  value = "${data.ibm_container_cluster_config.iks-cluster-config.config_file_path}"
}

output "ingress_hostname" {
  value = "${ibm_container_cluster.iks-cluster.ingress_hostname}"
}

output "ingress_secret" {
  value = "${ibm_container_cluster.iks-cluster.ingress_secret}"
}
