# -*- coding: utf-8 -*-
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: peers.proto
"""Generated protocol buffer code."""
from google.protobuf.internal import builder as _builder
from google.protobuf import descriptor as _descriptor
from google.protobuf import descriptor_pool as _descriptor_pool
from google.protobuf import symbol_database as _symbol_database
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()


import vendor.lightning_pb2 as lightning__pb2


DESCRIPTOR = _descriptor_pool.Default().AddSerializedFile(b'\n\x0bpeers.proto\x12\x08peersrpc\x1a\x0flightning.proto\"N\n\x13UpdateAddressAction\x12&\n\x06\x61\x63tion\x18\x01 \x01(\x0e\x32\x16.peersrpc.UpdateAction\x12\x0f\n\x07\x61\x64\x64ress\x18\x02 \x01(\t\"e\n\x13UpdateFeatureAction\x12&\n\x06\x61\x63tion\x18\x01 \x01(\x0e\x32\x16.peersrpc.UpdateAction\x12&\n\x0b\x66\x65\x61ture_bit\x18\x02 \x01(\x0e\x32\x11.lnrpc.FeatureBit\"\xad\x01\n\x1dNodeAnnouncementUpdateRequest\x12\x36\n\x0f\x66\x65\x61ture_updates\x18\x01 \x03(\x0b\x32\x1d.peersrpc.UpdateFeatureAction\x12\r\n\x05\x63olor\x18\x02 \x01(\t\x12\r\n\x05\x61lias\x18\x03 \x01(\t\x12\x36\n\x0f\x61\x64\x64ress_updates\x18\x04 \x03(\x0b\x32\x1d.peersrpc.UpdateAddressAction\"8\n\x1eNodeAnnouncementUpdateResponse\x12\x16\n\x03ops\x18\x01 \x03(\x0b\x32\t.lnrpc.Op*#\n\x0cUpdateAction\x12\x07\n\x03\x41\x44\x44\x10\x00\x12\n\n\x06REMOVE\x10\x01*i\n\nFeatureSet\x12\x0c\n\x08SET_INIT\x10\x00\x12\x15\n\x11SET_LEGACY_GLOBAL\x10\x01\x12\x10\n\x0cSET_NODE_ANN\x10\x02\x12\x0f\n\x0bSET_INVOICE\x10\x03\x12\x13\n\x0fSET_INVOICE_AMP\x10\x04\x32t\n\x05Peers\x12k\n\x16UpdateNodeAnnouncement\x12\'.peersrpc.NodeAnnouncementUpdateRequest\x1a(.peersrpc.NodeAnnouncementUpdateResponseB0Z.github.com/lightningnetwork/lnd/lnrpc/peersrpcb\x06proto3')

_builder.BuildMessageAndEnumDescriptors(DESCRIPTOR, globals())
_builder.BuildTopDescriptorsAndMessages(DESCRIPTOR, 'peers_pb2', globals())
if _descriptor._USE_C_DESCRIPTORS == False:

  DESCRIPTOR._options = None
  DESCRIPTOR._serialized_options = b'Z.github.com/lightningnetwork/lnd/lnrpc/peersrpc'
  _UPDATEACTION._serialized_start=459
  _UPDATEACTION._serialized_end=494
  _FEATURESET._serialized_start=496
  _FEATURESET._serialized_end=601
  _UPDATEADDRESSACTION._serialized_start=42
  _UPDATEADDRESSACTION._serialized_end=120
  _UPDATEFEATUREACTION._serialized_start=122
  _UPDATEFEATUREACTION._serialized_end=223
  _NODEANNOUNCEMENTUPDATEREQUEST._serialized_start=226
  _NODEANNOUNCEMENTUPDATEREQUEST._serialized_end=399
  _NODEANNOUNCEMENTUPDATERESPONSE._serialized_start=401
  _NODEANNOUNCEMENTUPDATERESPONSE._serialized_end=457
  _PEERS._serialized_start=603
  _PEERS._serialized_end=719
# @@protoc_insertion_point(module_scope)