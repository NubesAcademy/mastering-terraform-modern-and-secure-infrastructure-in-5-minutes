import requests
import json

# Create new version of firewall rules
cloudflare_ipv4_url = "https://www.cloudflare.com/ips-v4"
cloudflare_ipv6_url = "https://www.cloudflare.com/ips-v6"

cloudflare_ip_list = []

response = requests.get(cloudflare_ipv4_url)
if response.status_code != 200:
    print("Can't download of Cloudflare IPv4 list")
    quit()
for item in response.text.split("\n"):
    cloudflare_ip_list.append(item)

response = requests.get(cloudflare_ipv6_url)
if response.status_code != 200:
    print("Can't download of Cloudflare IPv6 list")
    quit()
for item in response.text.split("\n"):
    cloudflare_ip_list.append(item)

result = {
    "firewall_ips_https": "\n".join(cloudflare_ip_list)
}
json_result = json.dumps(result)
print(json_result)
