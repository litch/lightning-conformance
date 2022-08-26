import logo from './logo.svg';

import Flow from './Network';

import graph from './graph.json';

function App() {
  return (
    <div className="MyApp" style={{ height: 800 }}>
      <NetworkContainer />
    </div>
  );
}

function NetworkContainer() {
  let initialNodes = graph.nodes;
  let initialEdges = graph.edges;

  

  let formattedNodes = initialNodes.map((n) => {
    let x = Math.floor(Math.random() * 600);
    let y = Math.floor(Math.random() * 200);

    return ({
      id: n.pub_key,
      type: "default",
      data: {
        label: n.alias
      },
      position: { x, y }
    })
  })

  let formattedEdges = initialEdges.map((e) => {

    return ({
      id: e.channel_id,
      source: e.node1_pub,
      target: e.node2_pub,
    })
  })

  return(
    <Flow nodes={formattedNodes} edges={formattedEdges} />
  )

}



export default App;
