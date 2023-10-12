terraform {
  required_version = "1.5.7"
}

terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.44.1"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    region         = "eu-central-1"
    key            = "hetzner-example.tfstate"
    bucket         = "terraform-in-5-minutes"
  }
}

provider "hcloud" {
  # Configuration options
  token = "ndueSGkHGdNFfz64CEuSrS6st3whKu1yMAUbDfk3MAufB5IsawBlne8G5Io9UJVB"
}

provider "aws" {
  region = "eu-central-1"
}

variable "ssh_public_key" {
  description = "SSH public key contents"
  type        = string
}

resource "hcloud_ssh_key" "example" {
  name       = "example"
  public_key = var.ssh_public_key
}

data "external" "cloudflare_ips" {
  program = ["/usr/bin/python3", "${path.module}/scripts/cloudflare.py"]
}

locals {
  cloudflare_ips = split("\n", data.external.cloudflare_ips.result.firewall_ips_https)
}

resource "hcloud_firewall" "ssh" {
  name = "ssh"

  rule {
    direction = "in"
    protocol  = "tcp"
    port = "22"
    source_ips = [
      "0.0.0.0/0"
    ]
  }
}

resource "hcloud_firewall" "https" {
  name = "https"

  rule {
    direction = "in"
    protocol  = "tcp"
    port = "443"
    source_ips = local.cloudflare_ips
  }
}

resource "hcloud_server" "example" {
  name        = "example"
  image       = "ubuntu-22.04"
  server_type = "cx11"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.example.id]
  firewall_ids = [
    hcloud_firewall.ssh.id,
    hcloud_firewall.https.id
  ]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  user_data = <<EOD
#!/bin/sh
apt -y update
apt install -y apache2
EOD
}

