import os
import logging
import configparser
from flask import Flask, jsonify

from graph_server.lnd import describe_graph, get_info, get_nodes
from graph_server.flood import keysend_all_nodes
import graph_server.logging_config as logging_config
from graph_server.flood import random_merchant_traffic
from graph_server.channel import close_random_channel, force_close_random_channel

app = Flask(__name__, static_folder='../static', static_url_path='/')

config = configparser.ConfigParser()
config.read(f"./config/graph_server.ini")

logging_config.configure(config)

logger = logging.getLogger(__name__)
logger.info("Starting up")


@app.route('/')
def index():
    return app.send_static_file('index.html')

@app.route("/health")
def hello_world():
    return "<p>Yep, I'm here!</p>"

@app.route("/nodes")
def lnd_nodes():
    return get_nodes()

@app.route("/info/<string:node>")
def lnd_info(node):
    return get_info(node)

@app.route("/graph/<string:node>")
def lnd_graph(node):
    return describe_graph(node)

@app.route("/keysend_all/<string:sender>")
def _keysend_all_nodes(sender):
    return keysend_all_nodes(sender)

@app.route("/close-random/<string:node>")
def _close_random_channel(node):
    return close_random_channel(node)

@app.route("/force-close-random/<string:node>")
def _force_close_random_channel(node):
    return force_close_random_channel(node)


@app.route('/random_merchant_traffic')
def _random_merchant_traffic():
    return random_merchant_traffic(10)


if __name__ == "__main__":

    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)