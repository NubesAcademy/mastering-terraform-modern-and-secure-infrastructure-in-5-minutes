import requests
import json

# Define URLs for Cloudflare IPv4 and IPv6 lists.
cloudflare_ipv4_url = "https://www.cloudflare.com/ips-v4"
cloudflare_ipv6_url = "https://www.cloudflare.com/ips-v6"

# Initialize an empty list to store Cloudflare IP addresses.
cloudflare_ip_list = []

# Retrieve and process the Cloudflare IPv4 list.
response = requests.get(cloudflare_ipv4_url)
if response.status_code != 200:
    print("Can't download Cloudflare IPv4 list")
    quit() # Exit the script if the request fails.
for item in response.text.split("\n"):
    cloudflare_ip_list.append(item)

# Retrieve and process the Cloudflare IPv6 list.
response = requests.get(cloudflare_ipv6_url)
if response.status_code != 200:
    print("Can't download Cloudflare IPv6 list")
    quit() # Exit the script if the request fails.
for item in response.text.split("\n"):
    cloudflare_ip_list.append(item)

# Create a result dictionary containing the combined IP addresses.
result = {
    "firewall_ips_https": "\n".join(cloudflare_ip_list)
}

# Serialize the result dictionary to JSON format.
json_result = json.dumps(result)

# Print the JSON result.
print(json_result)
