# Define the required Terraform version.
terraform {
  required_version = "1.5.7"
}

# Define the required Terraform providers including versions.
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

  # Configure the backend for storing state files in an S3 bucket.
  backend "s3" {
    region         = "eu-central-1"
    key            = "hetzner-example.tfstate"
    bucket         = "terraform-in-5-minutes"
  }
}

# Define the Hetzner Cloud provider configuration.
provider "hcloud" {
  # token = "<HCLOUD_TOKEN>" # Replace with your actual Hetzner Cloud API token.
}

# Define the AWS provider configuration.
provider "aws" {
  region = "eu-central-1"
}

# Define a variable for the SSH public key.
variable "ssh_public_key" {
  description = "SSH public key contents"
  type        = string
}

# Create an SSH key resource in Hetzner Cloud.
resource "hcloud_ssh_key" "example" {
  name       = "example"
  public_key = var.ssh_public_key
}

# Use an external data source to run a Python script and obtain Cloudflare IPs.
data "external" "cloudflare_ips" {
  program = ["/usr/bin/python3", "${path.module}/scripts/cloudflare.py"]
}

# Split the Cloudflare IPs into a list for later use.
locals {
  cloudflare_ips = split("\n", data.external.cloudflare_ips.result.firewall_ips_https)
}

# Create a Hetzner Cloud firewall for SSH access.
resource "hcloud_firewall" "ssh" {
  name = "ssh"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = [
      "0.0.0.0/0" # Allow SSH from anywhere (0.0.0.0/0).
    ]
  }
}

# Create a Hetzner Cloud firewall for HTTPS access with Cloudflare IPs.
resource "hcloud_firewall" "https" {
  name = "https"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = local.cloudflare_ips
  }
}

# Create a Hetzner Cloud server instance.
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

  # Configure public network settings.
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  # Define user data for cloud-init.
  user_data = <<EOD
#!/bin/sh
apt -y update
apt install -y apache2
EOD
}
