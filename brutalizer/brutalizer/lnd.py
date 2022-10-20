from asyncio.log import logger
import grpc
import os
import codecs
import google.protobuf.json_format as json_format

from brutalizer.vendor import lightning_pb2 as ln
from brutalizer.vendor import lightning_pb2_grpc as lnrpc
from brutalizer.vendor import router_pb2_grpc as routerstub

# Due to updated ECDSA generated tls.cert we need to let gprc know that
# we need to use that cipher suite otherwise there will be a handhsake
# error when we communicate with the lnd rpc server.
os.environ["GRPC_SSL_CIPHER_SUITES"] = 'HIGH+ECDSA'

PORTS = {'lnd': 30009, 'lnd2': 30010}

def channel_for_node(node):
    cert = open(f"./auth/{node}.cert", 'rb').read()
    with open(f"./auth/{node}.macaroon", 'rb') as f:
        macaroon_bytes = f.read()
        macaroon = codecs.encode(macaroon_bytes, 'hex')

    def metadata_callback(context, callback):
        # for more info see grpc docs
        callback([('macaroon', macaroon)], None)

    cert_creds = grpc.ssl_channel_credentials(cert)
    auth_creds = grpc.metadata_call_credentials(metadata_callback)
    combined_creds = grpc.composite_channel_credentials(cert_creds, auth_creds)

    # finally pass in the combined credentials when creating a channel
    return grpc.secure_channel(f"localhost:{PORTS[node]}", combined_creds)

def router_stub_for_node(node):
    channel = channel_for_node(node)
    return routerstub.RouterStub(channel)

def stub_for_node(node):
    channel = channel_for_node(node)
    return lnrpc.LightningStub(channel)

def get_info(node):
    stub = stub_for_node(node)
    response = stub.GetInfo(ln.GetInfoRequest())
    print("Successfully retrieved info")
    return json_format.MessageToDict(response)

def generate_invoice(node, amount, description):
    stub = stub_for_node(node)
    response = stub.AddInvoice(ln.AddInvoiceRequest())


def describe_graph(node):
    stub = stub_for_node(node)
    response = stub.DescribeGraph(ln.ChannelGraphRequest())
    print("Successfully retrieved graph")
    return json_format.MessageToDict(response)


if __name__ == "__main__":
    stub = stub_for_node('lnd')
    response = stub.WalletBalance(ln.WalletBalanceRequest())
    print(response.total_balance)
    print(describe_graph('lnd'))