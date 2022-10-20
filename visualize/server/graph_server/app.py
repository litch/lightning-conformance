from flask import Flask, jsonify

from .lnd import describe_graph, get_info

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Yep, I'm here!</p>"

@app.route("/info/<string:node>")
def lnd_info(node):
    return get_info(node)

@app.route("/graph/<string:node>")
def lnd_graph(node):
    return describe_graph(node) 
