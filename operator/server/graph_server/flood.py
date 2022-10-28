from hashlib import sha256
from .lnd import describe_graph, stub_for_node, get_info, router_stub_for_node
from time import sleep
import codecs
import logging
import random
import secrets
import google.protobuf.json_format as json_format
from graph_server.vendor import lightning_pb2 as ln
from graph_server.vendor import router_pb2 as router

logger = logging.getLogger(__name__)

def send_bogus_payment(sender, receiver_pubkey, amt=100):
    sstub = router_stub_for_node(sender)
    
    dest_hex = receiver_pubkey
    dest_bytes = codecs.decode(dest_hex, 'hex')
    
    keySendPreimageType = 5482373484
    messageType = 34349334

    preimage_byte_length = 32
    preimage = secrets.token_bytes(preimage_byte_length)
    
    m = sha256()
    m.update(preimage)
    preimage_hash = m.digest()

    dest_custom_records = {
            keySendPreimageType: secrets.token_bytes(preimage_byte_length), # this is not the same preimage
            messageType: "wow a keysend".encode()
    }
    
    r = router.SendPaymentRequest(
        dest=dest_bytes, 
        amt=amt, 
        payment_hash=preimage_hash,
        dest_custom_records=dest_custom_records,
        timeout_seconds=10,
        fee_limit_msat=1999999
    )
        
    for response in sstub.SendPaymentV2(r):
        # print(response)
        pass

    # print("Final response: ", response)
    return response

def keysend(sender, receiver_pubkey, amt=1000):
    sstub = router_stub_for_node(sender)
    
    dest_hex = receiver_pubkey
    dest_bytes = codecs.decode(dest_hex, 'hex')
    
    keySendPreimageType = 5482373484
    messageType = 34349334

    preimage_byte_length = 32
    preimage = secrets.token_bytes(preimage_byte_length)
    
    m = sha256()
    m.update(preimage)
    preimage_hash = m.digest()

    dest_custom_records = {
            keySendPreimageType: preimage,
            messageType: "wow a keysend".encode()
    }
    
    r = router.SendPaymentRequest(
        dest=dest_bytes, 
        amt=amt, 
        payment_hash=preimage_hash,
        dest_custom_records=dest_custom_records,
        timeout_seconds=10,
        fee_limit_msat=19999
    )
        
    for response in sstub.SendPaymentV2(r):
        # print(response)
        pass

    # print("Final response: ", response)
    return response

def generate_invoice(node):
    nodestub = stub_for_node(node)
    hash = secrets.token_bytes(256 // 8)
    amt = secrets.randbelow(100000)
    r = ln.Invoice(
        value = amt,
        r_preimage = hash,
    )
    invoice = nodestub.AddInvoice(r)

    return invoice

def pay_invoice(node, invoice):
    sstub = router_stub_for_node(node)
    r = router.SendPaymentRequest(
        payment_request=invoice.payment_request,
        timeout_seconds=1
    )
    for response in sstub.SendPaymentV2(r):
        print(response)
    return response

def keysend_all_nodes(sender):
    logger.info(f"Keysending all nodes from {sender}")
    graph = describe_graph(sender)
    my_pubkey = get_info(sender).get('identityPubkey')
    nodes = graph.get('nodes')
    collection = []
    for node in nodes:
        dest = node.get('pubKey')
        logger.info(f"Sending to {dest}")
        if dest == my_pubkey:
            continue
        response = keysend(sender, dest, secrets.randbelow(1000000))
        message = f"Keysent (Destination: {dest}, Status: {response.status}, PaymentHash: {response.payment_hash}, FailureReason: {response.failure_reason}"
        logger.info(message)

        collection.append({
            'destination': dest,
            'status': response.status,
            'payment_hash': response.payment_hash,
            'failure_reason': response.failure_reason
        })
    success = 0
    failure = 0
    for result in collection:
        if result['status'] == 2:
            success += 1 
        if result['status'] == 3:
            failure += 1
    return {'success': success, 'failure': failure}


def random_merchant_traffic(number):
    merchant = 'lnd2'
    payers = ['lnd', 'lnd-15-0', 'lnd-15-1', 'lnd-15-2', 'lnd-15-3']
    collection = []
    for _ in range(number):
        invoice = generate_invoice(merchant)
        payer = random.choice(payers)
        result = pay_invoice(payer, invoice)
        logger.info(result)
        collection.append(result)
    success = 0
    failure = 0
    for result in collection:
        if result.status == 2:
            success += 1
        else:
            failure += 1
    return {'success': success, 'failure': failure}



def probe():
    l153 = '03a2161085f34baa02ae4b58bfad6b4f03488a624d39faecf0ae352a8f4b2073e0'
    amount = 2900000
    while True:
        result = send_bogus_payment('lnd', l153, amount)
        if result.failure_reason == 4:
            route = json_format.MessageToDict(result).get('htlcs')
            print(list(map(lambda h: h.get('chanId'), route[0].get('route').get('hops'))))
            print(f"Successfully got there, raise amount from {amount}")
            amount += 10000
        else:
            print("Failed along the route, success!")
            print(result)
            break

if __name__ == "__main__":
    receiver_pubkey = get_info('lnd2').get('identityPubkey')
    # send_bogus_payment('lnd', receiver_pubkey)
    
    # invoice = generate_invoice('lnd2')
    # print(invoice)
    # pay_invoice('lnd', invoice)
    # probe()

    keysend_all_nodes('lnd2')
    keysend_all_nodes('lnd')


# PaymentStatus
# Name	    Value	Description
# UNKNOWN	0	
# IN_FLIGHT	1	
# SUCCEEDED	2	
# FAILED	3

# PaymentFailureReason
# Name	                                    Value	Description
# FAILURE_REASON_NONE	                    0	Payment isn't failed (yet).
# FAILURE_REASON_TIMEOUT	                1	There are more routes to try, but the payment timeout was exceeded.
# FAILURE_REASON_NO_ROUTE	                2	All possible routes were tried and failed permanently. Or were no routes to the destination at all.
# FAILURE_REASON_ERROR	                    3	A non-recoverable error has occured.
# FAILURE_REASON_INCORRECT_PAYMENT_DETAILS	4	Payment details incorrect (unknown hash, invalid amt or invalid final cltv delta)
# FAILURE_REASON_INSUFFICIENT_BALANCE	    5	Insufficient local balance.