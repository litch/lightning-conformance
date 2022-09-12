#!/opt/homebrew/bin/python3

import os
import random
import subprocess
from subprocess import Popen, PIPE

import json
import uuid

class InvoicePaymentError(Exception):
    pass

class InvoiceGenerationError(Exception):
    pass

def generate_invoice_lnd(node):
    amount = round(random.random()*100000)
    # identifier = random.randbytes(32)
    generate_invoice_command = ['docker', 'exec', node, 'lncli', '--network=regtest', 'addinvoice', str(amount)]
    
    process = subprocess.run(generate_invoice_command, stdout=subprocess.PIPE, universal_newlines=True)
    output=process.stdout
    
    invoice = json.loads(output)['payment_request']
    return invoice

def generate_invoice_cln(node):
    amount = round(random.random()*100000)
    identifier = uuid.uuid4()
    generate_invoice_command = ['docker', 'exec', node, 'lightning-cli', '--network=regtest', 'invoice', str(amount), str(identifier), 'description']
    
    process = subprocess.run(generate_invoice_command, stdout=subprocess.PIPE, universal_newlines=True)
    output=process.stdout
    if process.returncode == 0:
        invoice = json.loads(output)['bolt11']
        return invoice
    else: 
        raise InvoiceGenerationError

def pay_invoice_cln(node, invoice):
    
    pay_invoice_command = ['docker', 'exec', node, 'lightning-cli', '--network=regtest', 'pay', invoice]
    
    process = subprocess.run(pay_invoice_command, stdout=subprocess.PIPE, universal_newlines=True)
    
    if process.returncode == 0:
        return process.stdout
    else:
        raise InvoicePaymentError

def send_cln_cln(sender, receiver):
    invoice = generate_invoice_cln(receiver)
    # print("Paying invoice: ", invoice)
    
    return pay_invoice_cln(sender, invoice)


c1_invoices = []
c4_invoices = []
for receiver in ['cln-remote', 'cln-c3', 'cln-c2', 'cln-hub']:
    c1_invoices.append(generate_invoice_cln(receiver))
for receiver in ['lnd', 'lnd2', 'lnd-15-0']:
    c1_invoices.append(generate_invoice_lnd(receiver))
for receiver in ['cln-remote', 'cln-c1', 'cln-c2', 'cln-hub']:
    c4_invoices.append(generate_invoice_cln(receiver))
node = 'cln-c1'
c1_cmds_list = [['docker', 'exec', node, 'lightning-cli', '--network=regtest', 'pay', invoice] for invoice in c1_invoices]
node = 'cln-c4'
c4_cmds_list = [['docker', 'exec', node, 'lightning-cli', '--network=regtest', 'pay', invoice] for invoice in c4_invoices]

cmds_list = c1_cmds_list+c4_cmds_list
print("Invoices retrieved - now paying")
procs_list = [Popen(cmd, stdout=PIPE, stderr=PIPE) for cmd in cmds_list]
for proc in procs_list:
	proc.wait()

def parse_result(proc):
    return proc.returncode

return_codes = list(map(parse_result,  procs_list))

success_count = return_codes.count(0)
error_count = return_codes.count(1)
print("Successfully sent: {}, Failed: {}".format(success_count, error_count))