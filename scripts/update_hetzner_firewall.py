#!/usr/bin/python3

import requests
import json

# Define HTTP request headers including the Hetzner Cloud (HCLOUD) token for authorization.
headers = {
    "Content-Type": "application/json; charset=utf-8",
    "Authorization": "Bearer <HCLOUD TOKEN>"  # Replace <HCLOUD TOKEN> with your actual Hetzner Cloud API token.
}

# Identify the firewall to be updated.
firewall_id = 0
response = requests.get("https://api.hetzner.cloud/v1/firewalls", headers=headers)
if (response.status_code != 200):
    print("Can't obtain a list of firewall rules")
    quit()  # Exit the script if the request fails.
json_response = response.json()
for item in json_response["firewalls"]:
    if item["name"] == "https":
        firewall_id = item["id"]
if firewall_id == 0:
    print("Can't find firewall rule")
    quit()

# Create a new version of firewall rules by obtaining Cloudflare IP lists.
cloudflare_ipv4_url = "https://www.cloudflare.com/ips-v4"
cloudflare_ipv6_url = "https://www.cloudflare.com/ips-v6"

cloudflare_ip_list = []

response = requests.get(cloudflare_ipv4_url)
if response.status_code != 200:
    print("Can't download Cloudflare IPv4 list")
    quit()  # Exit the script if the request fails.
for item in response.text.split("\n"):
    cloudflare_ip_list.append(item)

response = requests.get(cloudflare_ipv6_url)
if response.status_code != 200:
    print("Can't download Cloudflare IPv6 list")
    quit()  # Exit the script if the request fails.
for item in response.text.split("\n"):
    cloudflare_ip_list.append(item)

# Define the new firewall rules in a JSON format.
firewall_rules = {
    "rules": [
        {"direction": "in", "protocol": "tcp", "port": "443", "source_ips": cloudflare_ip_list, "destination_ips": [], "description": "Cloudflare"},
        {"direction": "in", "protocol": "tcp", "port": "80", "source_ips": cloudflare_ip_list, "destination_ips": [], "description": "Cloudflare"}
    ]
}

# Apply the new firewall rules to the identified firewall.
response = requests.post("https://api.hetzner.cloud/v1/firewalls/" + str(firewall_id) + "/actions/set_rules", headers=headers, json=firewall_rules)

# Print the HTTP response status code and text for debugging purposes.
print(response.status_code)
print(response.text)
