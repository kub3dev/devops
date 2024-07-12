resource "random_password" "cluster_token" {
  length  = 64
  special = false
}

resource "random_password" "bootstrap_token_id" {
  length  = 6
  upper   = false
  special = false
}

resource "random_password" "bootstrap_token_secret" {
  length  = 16
  upper   = false
  special = false
}

locals {
  token = "${random_password.bootstrap_token_id.result}.${random_password.bootstrap_token_secret.result}"
  common_k3s_args = [
    "--kube-apiserver-arg", "enable-bootstrap-token-auth",
    "--disable", "traefik",
    "--node-label", "az=ex1",
  ]
}

data "k8sbootstrap_auth" "auth" {
  server = module.server1.k3s_external_url
  token  = local.token
}

module "server1" {
  source = "../../k3s-hcloud"

  name          = "k3s-server-1"
  keypair_name  = hcloud_ssh_key.k3s.name
  network_id    = hcloud_network_subnet.k3s.network_id
  network_range = hcloud_network.k3s.ip_range

  cluster_token          = random_password.cluster_token.result
  k3s_args               = concat(["server", "--cluster-init"], local.common_k3s_args)
  bootstrap_token_id     = random_password.bootstrap_token_id.result
  bootstrap_token_secret = random_password.bootstrap_token_secret.result
}

module "servers" {
  source = "../../k3s-hcloud"

  count = var.server_count

  name          = "k3s-server-${count.index + 2}"
  keypair_name  = hcloud_ssh_key.k3s.name
  network_id    = hcloud_network_subnet.k3s.network_id
  network_range = hcloud_network.k3s.ip_range

  k3s_join_existing = true
  k3s_url           = module.server1.k3s_url
  cluster_token     = random_password.cluster_token.result
  k3s_args          = concat(["server"], local.common_k3s_args)
}

module "agent" {
  source = "../../k3s-hcloud"

  count = var.agent_count

  name          = "k3s-agent-${count.index + 1}"
  keypair_name  = hcloud_ssh_key.k3s.name
  network_id    = hcloud_network_subnet.k3s.network_id
  network_range = hcloud_network.k3s.ip_range

  k3s_join_existing = true
  k3s_url           = module.server1.k3s_url
  cluster_token     = random_password.cluster_token.result
  k3s_args          = ["agent", "--node-label", "az=ex1"]
}
