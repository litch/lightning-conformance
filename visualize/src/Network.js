import React, { useCallback } from 'react';
import ReactFlow, { MiniMap, Controls } from 'react-flow-renderer';

function Flow({ nodes, edges, onNodesChange, onEdgesChange, onConnect }) {
  console.log("Have nodes: ", nodes);
  console.log("Have edges: ", edges);
  
  return (
    <ReactFlow
      nodes={nodes}
      edges={edges}
      onNodesChange={onNodesChange}
      onEdgesChange={onEdgesChange}
      onConnect={onConnect}
      fitView>
     
    </ReactFlow>
  );
}


export default Flow;