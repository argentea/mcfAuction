/*************************************************************************
	> File Name: graph.h
	> Author: zhouyuan
	> Mail: 3294207721@qq.com 
	> Created Time: Sun Apr 25 05:56:14 2021
 ************************************************************************/

#ifndef _GRAPH_H
#define _GRAPH_H

#include <iostream>
#include <lemon/lgf_reader.h>
#include <lemon/lgf_writer.h>
#include <lemon/network_simplex.h>
#include <lemon/smart_graph.h>
using namespace lemon;

namespace mcfgraph {

template<class G, class NMI, class NMS, class AM, class N>
class GraphImpl{
public:
    GraphImpl() :
        _g(),
        _nodeLabel(_g),
        _supply(_g),
        _name(_g),
        _potential(_g),
        _arcLabel(_g),
        _capacity_upper(_g),
        _cost(_g),
        _flow(_g){}

    G &g() { return _g; }
    NMI *nodeLabel(){ return &_nodeLabel; }
    NMI *supply(){ return &_supply; }
    NMS *name(){ return &_name; }
    NMI *potential(){ return &_potential; }
    AM *arcLabel(){ return &_arcLabel; }
    AM *capacity_upper(){ return &_capacity_upper; }
    AM *cost(){ return &_cost; }
    AM *flow(){ return &_flow; }
    N *source(){ return &_source; }
    N *target(){ return &_target; }
    
    void getGraph(const char *fileName);
    
private:
    G _g;
    NMI _nodeLabel;
    NMI _supply;
    NMS _name;
    NMI _potential;
    AM _arcLabel;
    AM _capacity_upper;
    AM _cost;
    AM _flow;
    N _source;
    N _target;
};



template<class G, class NMI, class NMS, class AM, class N>
void GraphImpl<G, NMI, NMS, AM, N>::getGraph(const char* fileName){
    std::cerr << "input file: " << fileName << std::endl;
    std::cerr << "reading...\n";

    try{
        digraphReader<G>(_g, fileName).
            nodeMap("label", _nodeLabel).
            nodeMap("supply", _supply).
            nodeMap("name", _name).
            nodeMap("potential", _potential).

            node("source", _source).
            node("target", _target).
            arcMap("label", _arcLabel).
            arcMap("capacity_upper", _capacity_upper).
            arcMap("cost", _cost).
            arcMap("flow", _flow).
            run();
    } catch (Exception& error) {
        std::cerr << "Error: " << error.what() << std::endl;
        exit(1);
    }
    int numNodes = countNodes(_g);
    int numEdges = countArcs(_g);

    std::cout << "A digraph is read from '" << fileName << "'." << std::endl;
    std::cout << "Number of nodes: " << numNodes << std::endl;
    std::cout << "Number of arcs: " << numEdges << std::endl;


    NetworkSimplex<G> ns(_g);
    ns.upperMap(_capacity_upper).costMap(_cost).supplyMap(_supply).run();
    std::cout << "Total cost: " << ns.totalCost() << std::endl;
    ns.flowMap(_flow);
    ns.potentialMap(_potential);

    std::cout << "We can write it to the standard output:" << std::endl;

    digraphWriter(_g).                   // write g to the standard output
        nodeMap("label", _nodeLabel).
        nodeMap("supply", _supply).
        nodeMap("name", _name).
        nodeMap("potential",  _potential).

        node("source", _source).             // write s to 'source'
        node("target", _target).             // write t to 'target'

        arcMap("label", _arcLabel).
        arcMap("capacity", _capacity_upper).       // write cap into 'capacity'
        arcMap("cost", _cost).          // write 'cost' for for arcs
        arcMap("flow", _flow).          // write 'flow' for for arcs
        run();
    return ;
}




};//end namespace mcfgraph

#endif
