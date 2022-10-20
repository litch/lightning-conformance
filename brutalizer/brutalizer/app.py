from flask import Flask, jsonify

from .lnd import describe_graph, get_info
from .flood import keysend, keysend_all_nodes

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Yep, I'm here!</p>"

@app.route("/keysend_all/<string:node>")
def keysend_all(node):
    print(f"Keysending all nodes from {node}")
    return keysend_all_nodes(node)

