import React from 'react';
import ReactDOM from 'react-dom';
import CytoscapeComponent from 'react-cytoscapejs';

import Cytoscape from 'cytoscape';
import COSEBilkent from 'cytoscape-cose-bilkent';


Cytoscape.use(COSEBilkent);

class Visualize extends React.Component {
  constructor(props){
    super(props);
  }

  state = {
    graph: {nodes: [], edges: []},
    dataIsLoaded: false
  }

  componentDidMount() {
    fetch('/lnd-graph')
        .then((res) => res.json())
        .then((json) => {
          console.log("I have some json", json)
            this.setState({
                graph: json,
                dataIsLoaded: true
            });
        })
  }

  render() {  
    if (this.state.dataIsLoaded) {
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

      return <CytoscapeComponent 
        stylesheet={stylesheet} 
        elements={elements} 
        layout={layout} 
        style={ { width: '1800px', height: '1000px' } } />;
    } else {
      return <div>Loading...</div>
    }

  }
}

export default Visualize
