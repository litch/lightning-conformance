from hashlib import sha256
from .lnd import describe_graph, stub_for_node, get_info, router_stub_for_node
from time import sleep
import codecs
import secrets
from brutalizer.vendor import lightning_pb2 as ln
from brutalizer.vendor import router_pb2 as router

def send_bogus_payment(sender, receiver_pubkey):
    sstub = router_stub_for_node(sender)
    
    dest_hex = receiver_pubkey

    dest_bytes = codecs.decode(dest_hex, 'hex')

    hash = secrets.token_bytes(256 // 8)

    r = router.SendPaymentRequest(
        dest=dest_bytes, 
        amt=100, 
        timeout_seconds=10,
        payment_hash=hash)
    for response in sstub.SendPayment(r):
        print(response)

def keysend(sender, receiver_pubkey):
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
        amt=100, 
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

def keysend_all_nodes(sender):
    graph = describe_graph(sender)
    my_pubkey = get_info(sender).get('identityPubkey')
    nodes = graph.get('nodes')
    collection = []
    for node in nodes:
        dest = node.get('pubKey')
        if dest == my_pubkey:
            continue
        response = keysend(sender, dest)
        message = f"Keysent (Destination: {dest}, Status: {response.status}, PaymentHash: {response.payment_hash}, FailureReason: {response.failure_reason}"
        print(message)
        collection.append(message)
    return collection

if __name__ == "__main__":
    receiver_pubkey = get_info('lnd2').get('identityPubkey')
    # send_bogus_payment('lnd', receiver_pubkey)
    
    # invoice = generate_invoice('lnd2')
    # print(invoice)
    # pay_invoice('lnd', invoice)
    # l153 = '03a2161085f34baa02ae4b58bfad6b4f03488a624d39faecf0ae352a8f4b2073e0'
    # keysend('lnd', l153)
    keysend_all_nodes('lnd2')


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