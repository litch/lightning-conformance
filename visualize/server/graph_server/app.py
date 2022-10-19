from flask import Flask, jsonify

from .lnd import describe_graph

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Yep, I'm here!</p>"

@app.route("/lnd-graph")
def lnd_graph():
    graph_dict = describe_graph() 
    return graph_dict
