output "cluster_token" {
  value     = random_password.cluster_token.result
  sensitive = true
}

output "k3s_url" {
  value = module.server1.k3s_url
}

output "k3s_external_url" {
  value = module.server1.k3s_external_url
}

output "server_ip" {
  value = module.server1.node_ip
}

output "server_external_ip" {
  value = module.server1.node_external_ip
}

output "server_user_data" {
  value     = module.server1.user_data
  sensitive = true
}

output "token" {
  value     = local.token
  sensitive = true
}

output "ca_crt" {
  value = data.k8sbootstrap_auth.auth.ca_crt
}

output "kubeconfig" {
  value     = data.k8sbootstrap_auth.auth.kubeconfig
  sensitive = true
}
