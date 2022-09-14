#!/usr/bin/python3


import os
import random
import subprocess
import json

def normal(channel):
    if channel['state'] == 'CHANNELD_NORMAL':
        return True
    else:
        return False

cln_nodes = ["cln-c1", "cln-hub", "cln-c2", "cln-c3", "cln-c4", "cln-remote"]
node = random.sample(cln_nodes, 1)[0]

listfunds_command = ['docker', 'exec', node, 'lightning-cli', '--network=regtest', 'listfunds']

process = subprocess.run(listfunds_command, stdout=subprocess.PIPE, universal_newlines=True)
output = process.stdout

channels = json.loads(output)['channels']

ready_channels = list(filter(normal, channels))
if len(ready_channels) < 1:
    print("No ready channels")
    exit(0)
else:
    print(len(ready_channels))
# print("Ready channels: ", ready_channels)    
channel_to_close = random.choice(ready_channels)
# print("Channel to close ", channel_to_close)
scid = channel_to_close['short_channel_id']

print("Closing channel: ", channel_to_close)
close_channel_command = ['docker', 'exec', node, 'lightning-cli', '--network=regtest', 'close', scid]

process = subprocess.run(close_channel_command, stdout=subprocess.PIPE, universal_newlines=True)
output = process.stdout
if process.returncode == 0:
    print("Success: ", output)
else: 
    print("Error", output)
