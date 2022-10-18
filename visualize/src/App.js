import React from 'react';
import ReactDOM from 'react-dom';
import CytoscapeComponent from 'react-cytoscapejs';

import Cytoscape from 'cytoscape';
import COSEBilkent from 'cytoscape-cose-bilkent';

import graph from './graph.json';

Cytoscape.use(COSEBilkent);


class Visualize extends React.Component {
  constructor(props){
    super(props);
  }

  render() {
    let initialNodes = graph.nodes;
    let initialEdges = graph.edges;

    console.log(graph)

    let elements = [
    ];

    initialNodes.map((n) => {
      elements.push ({
        data: {
            id: n.pub_key,
            label: n.alias,
            alias: n.alias,
        }
      })
    })

    initialEdges.map((e) => {
      elements.push(
        {
          data: {
            source: e.node1_pub,
            target: e.node2_pub,
            capacity: Number(e.capacity).toLocaleString()
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
  }
}

export default Visualize
