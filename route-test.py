#!/usr/bin/python3
import os
import random
import subprocess
from subprocess import Popen, PIPE
from itertools import zip_longest
import time
import json
import uuid
from threading import Timer

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
    
    return pay_invoice_cln(sender, invoice)

cln_nodes = ['cln-remote', 'cln-c3', 'cln-c2', 'cln-hub', 'cln-c1', 'cln-c4']
lnd_nodes = ['lnd', 'lnd2', 'lnd-15-0']

cmds_list = []

print("Generating invoices")

for sender in cln_nodes:
    for receiver in lnd_nodes:
        invoice = generate_invoice_lnd(receiver)
        cmds_list.append(['docker', 'exec', sender, 'lightning-cli', '--network=regtest', 'pay', invoice])
    for receiver in cln_nodes:
        if receiver == sender:
            pass
        else:
            invoice = generate_invoice_cln(receiver)
            cmds_list.append(['docker', 'exec', sender, 'lightning-cli', '--network=regtest', 'pay', invoice])

for sender in lnd_nodes:
    for receiver in cln_nodes:
        invoice = generate_invoice_cln(receiver)
        cmds_list.append(['docker', 'exec', sender, 'lncli', '--network=regtest', 'payinvoice', '-f', invoice])
    for receiver in lnd_nodes:
        if receiver == sender:
            pass
        else:
            invoice = generate_invoice_lnd(receiver)
            cmds_list.append(['docker', 'exec', sender, 'lncli', '--network=regtest', 'payinvoice', '-f', invoice])

print("Invoices retrieved - now paying (Count: {})".format(len(cmds_list)))

def group_elements(n, iterable, padvalue='x'):
    return zip_longest(*[iter(iterable)]*n, fillvalue=padvalue)

def send_all():
    for group in group_elements(6, cmds_list, padvalue=None):
        start_time = time.time()
        procs_list = [Popen(cmd, stdout=PIPE, stderr=PIPE) for cmd in group]
        
        for proc in procs_list:
            proc.wait()

        def parse_result(proc):
            return proc.returncode


        return_codes = list(map(parse_result,  procs_list))
        end_time = time.time()
        success_count = return_codes.count(0)
        error_count = return_codes.count(1)
        print("Successfully sent: {}, Failed: {}, Elapsed time: {}".format(success_count, error_count, end_time-start_time))


def send_subset(count=10):
    start_time = time.time()
    random.shuffle(cmds_list)
    subset = cmds_list[0:count]
    print("Going to execute: ", subset)

    procs_list = [Popen(cmd, stdout=PIPE, stderr=PIPE) for cmd in subset]
    
    

    def parse_result(proc):
        return proc.returncode


    kill = lambda process: process.kill()
    
    my_timer = Timer(5, kill, [procs_list])
    try:
        my_timer.start()
        for proc in procs_list:
            proc.wait()
        # stdout, stderr = ping.communicate()
    finally:
        my_timer.cancel()


    return_codes = list(map(parse_result,  procs_list))
    end_time = time.time()
    success_count = return_codes.count(0)
    error_count = return_codes.count(1)
    print("Successfully sent: {}, Failed: {}, Elapsed time: {}".format(success_count, error_count, end_time-start_time))

def send_serially():
    start_time = time.time()
    random.shuffle(cmds_list)
    return_codes = []
    
    for cmd in cmds_list:
        try:
            print("Running: ", cmd)
            proc = subprocess.run(cmd, timeout=7, stdout=PIPE, stderr=PIPE)
            return_codes.append(proc.returncode)
        except subprocess.TimeoutExpired:
            return_codes.append(1)

    end_time = time.time()
    success_count = return_codes.count(0)
    error_count = return_codes.count(1)
    print("Successfully sent: {}, Failed: {}, Elapsed time: {}".format(success_count, error_count, end_time-start_time))

send_serially()
