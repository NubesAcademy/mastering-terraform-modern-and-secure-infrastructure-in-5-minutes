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

resource "hcloud_server" "example" {
  name        = "example"
  image       = "ubuntu-22.04"
  server_type = "cx11"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.example.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  user_data = <<EOD
#!/bin/sh
apt -y update
apt install -y apache2
EOD
}

