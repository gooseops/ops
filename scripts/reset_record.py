## WIP
## TODO: check dns record for current value using api
## Compare current response to dns record
## If different, change value

import requests

URL="https://ifconfig.me"

def get_current_ip(url:str=None):
    response=requests.get(url)
    return response.content.decode("utf-8")

ip=get_current_ip(URL)
print(ip)
