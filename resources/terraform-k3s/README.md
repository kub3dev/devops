# Terraform Modules for K3s

Provisions K3s nodes and is able to build a cluster from multiple nodes.

You can use the [k3s](./k3s) module to template the necessary cloudinit files for creating a K3s cluster node.
Modules for [OpenStack](./k3s-openstack) and [Hetzner hcloud](./k3s-hcloud) that bundle all necessary resources are available.

## Supported Cloud Providers
- OpenStack
- Hetzner Cloud (hcloud)

## Modules
### k3s
This module provides the templating of the user_data for use with cloud-init.

```terraform
module "k3s_server" {
  source = "git::https://github.com/nimbolus/tf-k3s.git//k3s"

  name          = "k3s-server"
  cluster_token = "abcdef"
  k3s_ip        = "10.11.12.13"
  k3s_args = [
    "server",
    "--disable", "traefik",
    "--node-label", "az=ex1",
  ]
}

output "server_user_data" {
  value     = module.k3s_server.user_data
  sensitive = true
}
```

### k3s-openstack
With this module a single K3s node can be deployed with OpenStack. It internally uses the k3s module. Depending on the supplied parameters the node will initialize a new cluster or join an existing cluster as a server or agent.

```terraform
module "server" {
  source = "git::https://github.com/nimbolus/tf-k3s.git//k3s-openstack"

  name               = "k3s-server"
  image_name         = "ubuntu-20.04"
  flavor_name        = "m1.small"
  availability_zone  = "ex"
  keypair_name       = "keypair"
  network_id         = var.network_id
  subnet_id          = var.subnet_id
  security_group_ids = [module.secgroup.id]

  cluster_token = "abcdef"
  k3s_args = [
    "server",
    "--disable", "traefik",
    "--node-label", "az=ex1",
    # if using bootstrap-auth include
    "--kube-apiserver-arg", "enable-bootstrap-token-auth",
  ]
  bootstrap_token_id     = "012345"
  bootstrap_token_secret = "0123456789abcdef"
}
```

### k3s-openstack/security-group
The necessary security-group for the K3s cluster can be deployed with this module.

```terraform
module "secgroup" {
  source = "git::https://github.com/nimbolus/tf-k3s.git//k3s-openstack/security-group"
}
```

### k3s-hcloud
With this module a single K3s node can be deployed with hcloud. It internally uses the k3s module. Depending on the supplied parameters the node will initialize a new cluster or join an existing cluster as a server or agent.

```terraform
module "server" {
  source = "git::https://github.com/nimbolus/tf-k3s.git//k3s-hcloud"

  name          = "k3s-server"
  keypair_name  = "keypair"
  network_id    = var.network_id
  network_range = var.ip_range

  cluster_token = "abcdef"
  k3s_args = [
    "server",
    "--disable", "traefik",
    "--node-label", "az=ex1",
    # if using bootstrap-auth include
    "--kube-apiserver-arg", "enable-bootstrap-token-auth",
  ]
  bootstrap_token_id     = "012345"
  bootstrap_token_secret = "0123456789abcdef"
}
```

## bootstrap-auth
To access the cluster an optional bootstrap token can be installed on the cluster. To install the token specify the parameters `bootstrap_token_id` and `bootstrap_token_secret` on the server that initializes the cluster.
For ease of use the provider [nimbolus/k8sbootstrap](https://registry.terraform.io/providers/nimbolus/k8sbootstrap/latest) can be used to retrieve the CA certificate from the cluster. The provider can also output a kubeconfig with the bootstrap token.

```terraform
data "k8sbootstrap_auth" "auth" {
  // depends_on = [module.secgroup] // if using OpenStack
  server = module.server1.k3s_external_url
  token  = local.token
}
```

## Examples
- [basic](examples/basic/main.tf): basic usage of the k3s module with one server and one agent node
- [ha-hcloud](examples/ha-hcloud/main.tf): 3 Servers and 1 Agent with bootstrap token on Hetzner Cloud
- [ha-openstack](examples/ha-openstack/main.tf): 3 Servers and 1 Agent with bootstrap token on OpenStack

## Tests
### Basic
```sh
cd tests/basic
go test -count=1 -v
```

### OpenStack
```sh
cd tests/ha-openstack
cp env.sample .env
$EDITOR .env
source .env
go test -count=1 -v
```

### hcloud
```sh
cd tests/ha-hcloud
cp env.sample .env
$EDITOR .env
source .env
go test -count=1 -v
```
