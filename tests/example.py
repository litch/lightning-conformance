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


AGENT_ID = 20235

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

def receive_payment(lnd1, lnd2, chan_id, amount):
    print("Sending payment")
    invoice = lnd1.add_invoice(amount, "test")
    print("Payment hash: ", invoice.r_hash)
    request = invoice.payment_request

    # Building route
    hh = ln.HopHint(chan_id=chan_id, node_id=lnd2.get_info().identity_pubkey)
    rh = ln.RouteHint(hop_hints=[hh])

    payment = lnd2.send_payment_v2(payment_request=request, route_hints=[rh], timeout_seconds=1)
    # print("Payment: ", payment.payment_hash)
    return payment

def validate_payment(payment, node_id, db):
    print("Validating payment: ", payment.payment_hash)
    db.execute("select id, payment_hash, is_keysend, amt_paid_msats, accept_time, resolve_time from payments_received where payment_hash = %s and node_id = %s", (payment.payment_hash, node_id,))
    record = db.fetchone()
    if record == None:
        raise AssertionError("Payment not found")
    assert record[2] == False
    assert record[3] == payment.value_msat
    assert record[4] == payment.creation_date
    assert record[5] == payment.creation_date

def test_receive_payment_over_channel(lnd1, lnd2, chan_id, amount, db):
    payment_messages = receive_payment(lnd1, lnd2, chan_id, amount)
    payment = payment_messages[-1]

    for _ in range(5):
        try:
            validate_payment(payment, node_id, db)
            return "Success!"
        except AssertionError as e:
            print(e)
            time.sleep(3)
            
    return "Error after all retries"

def validate_channel_collection(lnd1, node_id, db):
    print("Validating channel count")
    db.execute("select count(*) from channels inner join channel_state on channel_state.id = channels.state_id where node_id = %s and channel_state.val = 'ACTIVE'", (node_id,))
    record = db.fetchone()
    channels = lnd1.lightning_stub.ListChannels(ln.ListChannelsRequest()).channels
    assert record[0] == len(channels), f"Channel count: Surge: {record[0]} - LND: {len(channels)}"

    print("Channel count validated: DB: ", record[0], " - LND: ", len(channels))
    for channel in channels:
        db.execute("select channels.id, external_channel_id, channel_state.val from channels inner join channel_state on channel_state.id = channels.state_id where node_id = %s and external_channel_id = %s", (node_id, channel.chan_id))
        record = db.fetchone()
        if record == None:
            raise AssertionError("Channel not found")
        print("Channel: ", record[0], " - ", record[1], " - ", record[2])
        if record[2] == 'ACTIVE':
            assert channel.active == True

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

def channel_open_lifecycle(lnd1, lnd2, db, node_id):
    print("Opening channel")
    lnd2_pubkey = lnd2.lightning_stub.GetInfo(ln.GetInfoRequest()).identity_pubkey
    print("Destination pubkey: ", lnd2_pubkey)

    if check_peer(lnd1, lnd2) == False:
        
        connection_string = f"{lnd2_pubkey}@lnd2:9735"
        print(f"Adding peer {connection_string}")
        
        lnd1.lightning_stub.ConnectPeer(ln.ConnectPeerRequest(addr=ln.LightningAddress(pubkey=lnd2_pubkey, host="lnd2:9735")))
        
        print("Peer added, waiting a bit...")
        time.sleep(5)
        if check_peer(lnd1, lnd2) == False:
            raise AssertionError("Peer not found")
        print("Peer found")
    else:
        print("Peer already added")

    prepped_pubkey = bytes.fromhex(lnd2_pubkey)
    print("Prepared: ", prepped_pubkey)
    res = lnd1.lightning_stub.OpenChannelSync(
        ln.OpenChannelRequest(
            node_pubkey=prepped_pubkey,
            local_funding_amount=1000000, 
            push_sat=0, 
            private=False)
    )
    if res.funding_txid_bytes == None:
        raise AssertionError("Channel not opened")
    
    txid = res.funding_txid_bytes.hex()
    

    mine_block()

    print("Channel opened: ", txid)

    pending_channels = lnd1.lightning_stub.PendingChannels(ln.PendingChannelsRequest())

    # Collect the pending open channel ids
    pending_open_channels = pending_channels.pending_open_channels
    pending_open_channel_ids = []
    for pending_open_channel in pending_open_channels:
        pending_open_channel_ids.append(pending_open_channel.channel.channel_point.split(':')[0])
    print("Pending open channel ids: ", pending_open_channel_ids)
    

    if txid not in pending_open_channel_ids:
        print("Txid not found in pending open channels")
    else:
        print("Txid found in pending open channels")
    
    # Let's try reversing the bytes
    rev_txid = res.funding_txid_bytes[::-1].hex()
    if rev_txid not in pending_open_channel_ids:
        print("Reversed txid not found in pending open channels")
    else:
        print("Reversed txid found in pending open channels")

    return None

    mine_block()
    
    record = wait_for_channel(db, node_id, rev_txid)
    print("Pending open channel detected in Surge")
    for _ in range(6):
        mine_block()
    
    record = wait_for_channel(db, node_id, rev_txid, "ACTIVE")


def wait_for_channel(db, node_id, rev_txid, status="PENDING_OPEN"):
    for _ in range(10):
        try:
            print(f"Waiting for channel to become {status} - txid: {rev_txid}, node_id {node_id}")
            db.execute("select channels.id, channel_state.val from channels inner join channel_state on channel_state.id = channels.state_id where node_id = %s and channel_open_txid = %s", (node_id, rev_txid,))
            record = db.fetchone()
            if record == None:
                raise AssertionError("Channel not found")
            print("Channel: ", record[0], " - ", record[1])
            if record[1] == status:
                return record
            else:
                print("Channel not in desired status, waiting 10 seconds...")
                time.sleep(10)
        except AssertionError as e:
            print(e)
            time.sleep(5)
    raise AssertionError("Channel not found")

def close_all_channels(lnd):
    channels = lnd.lightning_stub.ListChannels(ln.ListChannelsRequest()).channels
    for channel in channels:
        print("Closing channel: ", channel.chan_id)
        channel_point = ln.ChannelPoint(funding_txid_bytes=bytes.fromhex(channel.channel_point.split(':')[0]), output_index=int(channel.channel_point.split(':')[1]))

        res = lnd.lightning_stub.CloseChannel(ln.CloseChannelRequest(channel_point=channel_point, force=False  ))
        print(res)
        time.sleep(1)
    mine_block()

def disconnect_all_peers(lnd):
    peer_list = lnd.lightning_stub.ListPeers(ln.ListPeersRequest())
    for peer in peer_list.peers:
        print("Disconnecting peer: ", peer.pub_key)
        lnd.lightning_stub.DisconnectPeer(ln.DisconnectPeerRequest(pub_key=peer.pub_key))
        time.sleep(5)
    mine_block()

# postgres://tsdbadmin:xlwo0rndweaduo66@x1wxu0povc.i8of53mz3a.tsdb.cloud.timescale.com:37927/tsdb



# with psycopg.connect(conninfo="postgres://tsdbadmin:xlwo0rndweaduo66@x1wxu0povc.i8of53mz3a.tsdb.cloud.timescale.com:37927/tsdb") as conn:

#     # Open a cursor to perform database operations
#     with conn.cursor() as cur:
#         cur.execute("select node_id from agents where id = %s", (AGENT_ID,))

#         node_id = cur.fetchone()[0]
#         print("Node ID: ", node_id)

#         lnd1 = build_lnd1()
#         lnd2 = build_lnd2()
        
#         for found_channel in get_channels(lnd1, lnd2):
#             print(found_channel)
#             validate_channel(found_channel, node_id, cur)
#             print(test_receive_payment_over_channel(lnd1, lnd2, found_channel.chan_id, 1000, cur))
#             pass

#         # validate_channel_collection(lnd1, cur)
#         channel_open_lifecycle(lnd1, lnd2, cur)

def main():
    lnd1 = build_lnd1()
    lnd2 = build_lnd2()
    # lnd3 = build_lnd3()
    with psycopg.connect(conninfo="postgres://tsdbadmin:xlwo0rndweaduo66@x1wxu0povc.i8of53mz3a.tsdb.cloud.timescale.com:37927/tsdb") as conn:

        # Open a cursor to perform database operations
        with conn.cursor() as cur:
            cur.execute("select node_id from agents where id = %s", (AGENT_ID,))
            node_id = cur.fetchone()[0]
            print("Node ID: ", node_id)
    

            print("Started successfully")

            # validate_channel_collection(lnd1, node_id, cur)

            channel_open_lifecycle(lnd1, lnd2, cur, node_id)
    
    # close_all_channels(lnd1)
    # disconnect_all_peers(lnd1)


if __name__ == "__main__":
    main()

