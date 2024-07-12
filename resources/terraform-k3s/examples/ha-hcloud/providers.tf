provider "kubernetes" {
  host                   = module.server1.k3s_url
  token                  = local.token
  cluster_ca_certificate = data.k8sbootstrap_auth.auth.ca_crt
}
