import React from 'react';
import ReactDOM from 'react-dom';
import CytoscapeComponent from 'react-cytoscapejs';

import Cytoscape from 'cytoscape';
import COSEBilkent from 'cytoscape-cose-bilkent';
import './App.css'

Cytoscape.use(COSEBilkent);

class Visualize extends React.Component {
  constructor(props){
    super(props);
  }

  state = {
    connectableNodes: [],
    w: 0,
    h: 0,
    graph: {nodes: [], edges: []},
    graphIsLoaded: false,
    info: {},
    infoIsLoaded: false,
    busy: false,
    response: null,
  }

  componentDidMount = () => {
    this.setState({
      w: window.innerWidth,
      h: window.innerHeight
    })
    // this.setUpListeners()
    this.cy = null
    this.fetchConnectableNodes()
    this.fetchData()
    this.interval = setInterval(this.fetchData, 2000)
  }

  fetchConnectableNodes = () => {
    fetch('/nodes')
        .then((res) => res.json())
        .then((json) => {
            console.log("Got nodes", json)
            this.setState({
                connectableNodes: json,
            });
            this.setNode(json[0].name)
        })
  }

  fetchData = () => {
    if (!this.state.node) {
      return
    }
    fetch('/graph/'+this.state.node)
        .then((res) => res.json())
        .then((json) => {
            this.setState({
                graph: json,
                graphIsLoaded: true,
            });
        })
    fetch('/info/'+this.state.node)
        .then((res) => res.json())
        .then((json)=> {
          this.setState({
            info: json,
            infoIsLoaded: true,
          })
        })
  }

  componentWillUnmount() {
    clearInterval(this.interval)
  }

  setNode(node) {
    this.setState({node, infoIsLoaded: false})
  }

  render() {
    return <div className='container'>
      <div className='info'>
        <div>
          <h1>Visualize</h1>

          <ConnectButtons connectableNodes={this.state.connectableNodes} setNode={(node) => this.setNode(node)} />
          <Info info={this.state.info} infoIsLoaded={this.state.infoIsLoaded} />

        </div>
        <div>
          {JSON.stringify(this.state.result)}
        </div>
      </div>

      {this.state.graphIsLoaded ? <Graph graph={this.state.graph} h={this.state.h} w={this.state.w} /> : <div></div>}
    </div>
  }
}

function ConnectButtons(props) {
  let connectableNodes = props.connectableNodes;
  let setNode = props.setNode;
  return <div>
    {connectableNodes.map((n) => {
      return <button onClick={() => setNode(n.name)}>{n.name}</button>
    })}
  </div>
}


function Graph(props) {
  console.log("Drawing!", props)
  let initialNodes = props.graph.nodes;
  let initialEdges = props.graph.edges || [];
  let setCy = props.setCy;
  let elements = [];

  initialNodes.map((n) => {
    let id = n.pubKey;
    let alias = n.alias || n.pubKey;
    let label = n.alias || n.pubKey.substring(0,5)+"...";
    console.log("Pushing node", id, alias, label)
    elements.push ({
      data: {
          id: id,
          label: label,
          alias: label,
      }
    })
  })

  initialEdges.map((e) => {
    let capacity =  Number(e.capacity).toLocaleString();
    elements.push(
      {
        data: {
          source: e.node1Pub,
          target: e.node2Pub,
          capacity
        }
      }
    )
  })

  const layout = { name: 'cose-bilkent' };

  const stylesheet = [
    {
      selector: 'node',
      style: {
        'label': 'data(alias)',
        'font-size': 12,
      }
    },
    {
      selector: 'edge',
      style: {
        "target-arrow-shape": "triangle",
        "curve-style": "bezier",
        "width": 1,
        'label': 'data(capacity)',
        'font-size': 9,
        'color': 'green'
      }
    }
  ]

  return <div className='graph'>
        <CytoscapeComponent
          // cy={(cy) => { setCy(cy) }}
          stylesheet={stylesheet}
          elements={elements}
          layout={layout}
          style={ { width: props.w, height: props.h } } />;
    </div>
}

function Info(props) {
  console.log("Props", props)
  let info = props.info;
  let infoIsLoaded = props.infoIsLoaded;

  if (infoIsLoaded) {
    return <div>
      <dl>
        <dt>Alias</dt>
        <dd>{info.alias}</dd>
        <dt>Blockheight</dt>
        <dd>{info.blockHeight}</dd>
        <dt># Peers</dt><dd>{info.numPeers}</dd>
        <dt># Active Channels</dt><dd>{info.numActiveChannels}</dd>
        <dt>Synced to Chain</dt><dd>{info.syncedToChain ? "True" : "False"}</dd>
        <dt>Synced to Graph</dt><dd>{info.syncedToGraph ? "True" : "False"}</dd>
        <dt>Version</dt><dd>{info.version}</dd>
      </dl>
    </div>
  } else {
    return <div>Loading...</div>
  }
}

export default Visualize
