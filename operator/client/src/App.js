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
    graph: {nodes: [], edges: []},
    graphIsLoaded: false,
    info: {},
    infoIsLoaded: false,
    cy: null
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

  componentDidMount() {
    this.fetchData();
    this.interval = setInterval(this.fetchData, 2000)
  }

  componentWillUnmount() {
    clearInterval(this.interval)
  }

  setNode(node) {
    this.setState({node, infoIsLoaded: false})
  }

  render() {  
    if (this.state.graphIsLoaded) {
      let initialNodes = this.state.graph.nodes;
      let initialEdges = this.state.graph.edges;

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
        let source = e.node1Pub;
        let target = e.node2Pub;
        let capacity =  Number(e.capacity).toLocaleString();
        console.log("Pushing edge", source, target, capacity)
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

      return <div className='container'>
          <div className='info'>
            <button onClick={() => this.setNode('lnd')} disabled={this.state.node == 'lnd'}>
              LND
            </button>
            <button onClick={() => this.setNode('lnd2')} disabled={this.state.node == 'lnd2'}>
              LND2
            </button>
            <Info info={this.state.info} infoIsLoaded={this.state.infoIsLoaded} /> 
          </div>
          <div className='graph'>
            <CytoscapeComponent 
              cy={(cy) => { this.cy = cy }}
              stylesheet={stylesheet} 
              elements={elements} 
              layout={layout} 
              style={ { width: '1800px', height: '1000px' } } />;
        </div>
      </div>
    } else {
      return <div>Loading...</div>
    }

  }
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
