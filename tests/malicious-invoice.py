import psycopg
import time
import subprocess
import vendor.lightning_pb2 as ln
import vendor.lightning_pb2_grpc as lnrpc
import vendor.peers_pb2_grpc as peers
import vendor.router_pb2_grpc as router
import grpc
import codecs
import hashlib

class LndClient:
    def __init__(self, host, port, macaroon_path, tls_cert_path):
        self.host = host
        self.port = port
        self.macaroon_path = macaroon_path
        self.tls_cert_path = tls_cert_path

        self.channel = self.build()
        self.lightning_stub = lnrpc.LightningStub(self.channel)
        self.peers_stub = peers.PeersStub(self.channel)
        self.router_stub = router.RouterStub(self.channel)

    def build(self):
        tls_cert = open(self.tls_cert_path, "rb").read()
        macaroon = codecs.encode(open(self.macaroon_path, "rb").read(), "hex")
        cert_creds = grpc.ssl_channel_credentials(tls_cert)
        auth_creds = grpc.metadata_call_credentials(self._macaroon_call(macaroon))
        creds = grpc.composite_channel_credentials(cert_creds, auth_creds)
        channel = grpc.secure_channel(f"{self.host}:{self.port}", creds)
        return channel


    def _macaroon_call(self, macaroon):
        def metadata_callback(context, callback):
            callback([('macaroon', macaroon)], None)
        return metadata_callback

def build_lnd1():
    host = "127.0.0.1"
    port = 30009
    
    macaroon_path='../volumes/lnd/data/chain/bitcoin/regtest/admin.macaroon'
    tls_cert_path='../volumes/lnd/tls.cert'
    
    return LndClient(host, port, macaroon_path, tls_cert_path)

def build_lnd2():
    host = "127.0.0.1"
    port = 30010
    
    macaroon_path='../volumes/lnd2/data/chain/bitcoin/regtest/admin.macaroon' 
    tls_cert_path='../volumes/lnd2/tls.cert'

    return LndClient(host, port, macaroon_path, tls_cert_path)


def build_lnd3():
    host = "127.0.0.1"
    port = "55522"
    macaroon_path='../volumes/lnd-15-5/data/chain/bitcoin/regtest/admin.macaroon' 
    tls_cert_path='../volumes/lnd-15-5/tls.cert'

    return LndClient(host, port, macaroon_path, tls_cert_path)


def get_channels(start, end):
    print("Checking channel between ", start, " and ", end)
    channels = start.list_channels()
    response = []
    for channel in channels.channels:
        if channel.remote_pubkey == end.get_info().identity_pubkey:
            print("Channel found! - chan_id: ", channel.chan_id)
            response.append(channel)
    return response
        
def validate_channel(channel, node_id, db):
    print("Validating channel: ", channel.chan_id)
    db.execute("select channels.id, channel_point, capacity, local_balance, remote_balance, total_sats_sent, opened_at, closed_at, channel_state.val as state from channels inner join channel_state on channel_state.id = channels.state_id where external_channel_id = %s and node_id = %s", (found_channel.chan_id, node_id,))
    record = db.fetchone()
    assert record[2] == found_channel.capacity
    # assert record[3] == found_channel.local_balance, f"Local balance: {record[3]} - {found_channel.local_balance}"
    # assert record[4] == found_channel.remote_balance, f"Remote balance: {record[4]} - {found_channel.remote_balance}"
    assert record[5] == found_channel.total_satoshis_sent, f"Total sats sent: {record[5]} - {found_channel.total_satoshis_sent}"
    # assert(record[6] == found_channel.opening_height)
    # assert(record[7] == found_channel.closing_height)
    assert record[8] == 'ACTIVE', f"Channel state: {record[8]} - {found_channel.active}"


def mine_block():
    print("Mining block")
    # docker exec bitcoin bitcoin-cli -datadir=config -rpcwallet=rpcwallet -generate=1
    
    # run this subprocess and supress output
    subprocess.run(['docker', 'exec', 'bitcoin', 'bitcoin-cli', '-datadir=config', '-rpcwallet=rpcwallet', '-generate=1'])
    return None
    
def check_peer(lnd1, lnd2):
    peer_list = lnd1.lightning_stub.ListPeers(ln.ListPeersRequest())
    lnd2_pubkey = lnd2.lightning_stub.GetInfo(ln.GetInfoRequest()).identity_pubkey
    for peer in peer_list.peers:
        if peer.pub_key == lnd2_pubkey:
            return True
    return False

def generate_invoice(amount, memo, lnd):
    print("Generating invoice")
    invoice = lnd.lightning_stub.AddInvoice(ln.Invoice(value=amount, memo=memo))
    print("Invoice generated: ", invoice.payment_request)
    return invoice.payment_request

def decode_invoice(invoice, lnd):
    print("Decoding invoice")
    decoded = lnd.lightning_stub.DecodePayReq(ln.PayReqString(pay_req=invoice))
    return decoded

def main():
    lnd1 = build_lnd1()
    lnd2 = build_lnd2()
    # lnd3 = build_lnd3()
    lnd1_pubkey = lnd1.lightning_stub.GetInfo(ln.GetInfoRequest()).identity_pubkey
    print("Lnd1 pubkey: ", lnd1_pubkey)
    invoice_a = generate_invoice(amount=1000000, memo="malicious invoice1", lnd=lnd1)
    invoice_bprime = generate_invoice(amount=1000, memo="malicious invoice2", lnd=lnd1)
    r_hash_a = decode_invoice(invoice_a, lnd1).payment_hash
    decoded_bprime = decode_invoice(invoice_bprime, lnd1)
    decoded_bprime.payment_hash = r_hash_a
    invoice_b = lnd1.lightning_stub.AddInvoice(decoded_bprime)
    

    # now pay the invoice
    print("Paying invoice")
    pay_req = invoice_b.payment_request
    payment = lnd2.lightning_stub.SendPaymentSync(ln.SendRequest(payment_request=pay_req))
    print("Payment sent: ", payment.payment_route)
    print("Payment status: ", payment.payment_error)
    
    # check all invoice statuses for lnd1
    print("Checking invoice status")
    invoice_status = lnd1.lightning_stub.ListInvoices(ln.ListInvoiceRequest())
    # show the state and value of the last 4 invoices
    for invoice in invoice_status.invoices[-4:]:
        print(f"Invoice: {invoice.add_index} | {invoice.memo} | State: {invoice.state} | Value: {invoice.value}")


if __name__ == "__main__":
    main()

