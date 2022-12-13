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
    node: 'lnd',
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
    this.fetchData()
    this.interval = setInterval(this.fetchData, 2000)
  }
  

  fetchData = () => {
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

  keysendAll() {
    this.setState({busy: true, result: null})
    fetch('/keysend_all/'+this.state.node)
        .then((res) => res.json())
        .then((json) => {
            this.setState({
                result: json,
                busy: false,
            });
        })
  }

  randomMerchantTraffic() {
    this.setState({busy: true, result: null})
    fetch('/random_merchant_traffic')
        .then((res) => res.json())
        .then((json) => {
            this.setState({
                result: json,
                busy: false,
            });
        })
  }

  closeRandomChannel() {
    this.setState({busy: true, result: null})
    fetch('/close-random/'+this.state.node)
        .then((res) => res.json())
        .then((json) => {
            this.setState({
                result: json,
                busy: false,
            });
        })
  }

  forceCloseRandomChannel() {
    this.setState({busy: true, result: null})
    fetch('/force-close-random/'+this.state.node)
        .then((res) => res.json())
        .then((json) => {
            this.setState({
                result: json,
                busy: false,
            });
        })
  }

  setCy(cy) {
    console.log("Hi", cy, this.cy)
    this.cy = cy
  }

  render() {  
    return <div className='container'>
      <div className='info'>
        <button onClick={() => this.setNode('lnd')} disabled={this.state.node == 'lnd'}>
          LND
        </button>
        <button onClick={() => this.setNode('lnd2')} disabled={this.state.node == 'lnd2'}>
          LND2
        </button>
        <Info info={this.state.info} infoIsLoaded={this.state.infoIsLoaded} /> 
        <button onClick={() => this.keysendAll() } disabled={this.state.busy}>
          Keysend all visible nodes
        </button>
        <button onClick={() => this.randomMerchantTraffic() } disabled={this.state.busy}>
          Random Merchant Traffic
        </button>
        <button onClick={() => this.closeRandomChannel() } disabled={this.state.busy}>
          Close Random Channel
        </button>
        <button onClick={() => this.forceCloseRandomChannel() } disabled={this.state.busy}>
          Force Close Random Channel
        </button>
        {JSON.stringify(this.state.result)}
      </div>
      
      {this.state.graphIsLoaded ? <Graph graph={this.state.graph} setCy={this.setCy} h={this.state.h} w={this.state.w} /> : <div>Loading</div>}
    </div>
  }
}


function Graph(props) {
  console.log("Drawing!", props)
  let initialNodes = props.graph.nodes;
  let initialEdges = props.graph.edges;

  let elements = [
  ];

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
          cy={(cy) => { props.setCy(cy) }}
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
      {/* {JSON.stringify(info)} */}
    </div>
  } else {
    return <div>Loading...</div>
  }
}

export default Visualize
