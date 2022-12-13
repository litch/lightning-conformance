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

def close_random_channel(node):
    nodestub = stub_for_node(node)
    r = ln.ListChannelsRequest()

    channels_message = nodestub.ListChannels(r)
    channels = channels_message.channels

    candidates = []
    for channel in channels:
        print(channel)
        if channel.active:
            candidates.append((channel.channel_point, channel.active))

    selected = candidates[0][0]
    print("Selected: ", selected)
    funding_txid, output_index = selected.split(":")
    _channel_point = channel_point_generator(
        funding_txid=funding_txid, output_index=output_index
    )

    close_request = ln.CloseChannelRequest(channel_point = _channel_point)
    
    response = nodestub.CloseChannel(close_request)    
    print(response)
    return selected
    
def force_close_random_channel(node):
    nodestub = stub_for_node(node)
    r = ln.ListChannelsRequest()

    channels_message = nodestub.ListChannels(r)
    channels = channels_message.channels

    candidates = []
    for channel in channels:
        print(channel)
        if channel.active:
            candidates.append((channel.channel_point, channel.active))

    selected = candidates[0][0]
    print("Selected: ", selected)
    funding_txid, output_index = selected.split(":")
    _channel_point = channel_point_generator(
        funding_txid=funding_txid, output_index=output_index
    )

    close_request = ln.CloseChannelRequest(channel_point = _channel_point, force = True)
    
    response = nodestub.CloseChannel(close_request)    
    print(response)
    return selected
    




def channel_point_generator(funding_txid, output_index):
    """
    Generate a ln.ChannelPoint object from a funding_txid and output_index
    :return: ln.ChannelPoint
    """
    return ln.ChannelPoint(
        funding_txid_str=funding_txid, output_index=int(output_index)
    )