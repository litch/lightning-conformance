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
            capacity: e.capacity
          }
        }
      )
    })
    const layout = { name: 'cose-bilkent' };

    const stylesheet = [
      {
        selector: 'node',
        style: {
          'label': 'data(alias)'
        }
      },
      {
        selector: 'edge',
        style: {
          "target-arrow-shape": "triangle",   
          "curve-style": "bezier",
          "width": 1,
          'label': 'data(capacity)'
        }
      }
    ]

    return <CytoscapeComponent 
      stylesheet={stylesheet} 
      elements={elements} 
      layout={layout} 
      style={ { width: '1000px', height: '1000px' } } />;
  }
}

export default Visualize
// import logo from './logo.svg';

// import Flow from './Network';

// import graph from './graph.json';

// function App() {
//   return (
//     <div className="MyApp" style={{ height: 800 }}>
//       <NetworkContainer />
//     </div>
//   );
// }

// function NetworkContainer() {
//   let initialNodes = graph.nodes;
//   let initialEdges = graph.edges;

//   let formattedNodes = initialNodes.map((n) => {
//     let x = Math.floor(Math.random() * 600);
//     let y = Math.floor(Math.random() * 200);

//     return ({
//       id: n.pub_key,
//       type: "default",
//       data: {
//         label: n.alias
//       },
//       position: { x, y }
//     })
//   })

//   let formattedEdges = initialEdges.map((e) => {

//     return ({
//       id: e.channel_id,
//       source: e.node1_pub,
//       target: e.node2_pub,
//     })
//   })

//   return(
//     <Flow nodes={formattedNodes} edges={formattedEdges} />
//   )

// }



// export default App;
