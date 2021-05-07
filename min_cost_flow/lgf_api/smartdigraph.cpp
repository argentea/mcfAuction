/*************************************************************************
  > File Name: smartdigrapth.cpp
  > Author: zhouyuan
  > Mail: 3294207721@qq.com 
  > Created Time: Thu Apr 22 02:29:52 2021
 ************************************************************************/

#include<iostream>
#include <lemon/smart_graph.h>
#include <lemon/lgf_reader.h>
#include <lemon/lgf_writer.h>
//#include <lemon/capacity_scaling.h>
#include <lemon/network_simplex.h>
#include "graph.h"
using namespace mcfgraph;
using namespace lemon;
void getSmartDigraph(const char* fileName, std::shared_ptr<GraphImpl> gra){
    std::cerr << "input file: " << fileName << std::endl;
    std::cerr << "reading...\n";

    SmartDigraph &g = gra->g();

    SmartDigraph::NodeMap<int> 
        &nodeLabel = *(gra->nodeLabel()),
        &supply = *(gra->supply()),
        &potential = *(gra->potential());

    SmartDigraph::NodeMap<std::string> 
        &name = *(gra->name());

    SmartDigraph::ArcMap<int>
        &arcLabel = *(gra->arcLabel()),
        &capacity_upper = *(gra->capacity_upper()),
        &cost = *(gra->cost()),
        &flow = *(gra->flow());

    SmartDigraph::Node 
        &source = *(gra->source()), 
        &target = *(gra->target());


    try{
        digraphReader<SmartDigraph>(g, fileName).
            nodeMap("label", nodeLabel).
            nodeMap("supply", supply).
            nodeMap("name", name).
            nodeMap("potential", potential).

            node("source", source).
            node("target", target).
            arcMap("label", arcLabel).
            arcMap("capacity_upper", capacity_upper).
            arcMap("cost", cost).
            arcMap("flow", flow).
            run();
    } catch (Exception& error) {
        std::cerr << "Error: " << error.what() << std::endl;
        exit(1);
    }
    int numNodes = countNodes(g);
    int numEdges = countArcs(g);

    std::cout << "A digraph is read from '" << fileName << "'." << std::endl;
    std::cout << "Number of nodes: " << numNodes << std::endl;
    std::cout << "Number of arcs: " << numEdges << std::endl;


    NetworkSimplex<SmartDigraph> ns(g);
    ns.upperMap(capacity_upper).costMap(cost).supplyMap(supply).run();
    std::cout << "Total cost: " << ns.totalCost<int>() << std::endl;
    ns.flowMap(flow);
    ns.potentialMap(potential);
    /*  std::cout << "flow :" << std::endl;
    /  for (SmartDigraph::ArcIt a(gra->g()); a != INVALID; ++a) {
        std::cout << "flow[" << g.id(a)<< "] = " << ns.flow(a) << std::endl;
        }

        std::cout << "potential :" << std::endl;
        for (SmartDigraph::NodeIt n(gra->g()); n != INVALID; ++n) {
        std::cout << "potential[" << g.id(n) << "] = " << ns.potential(n) << std::endl;
        }
    */  
    std::cout << "We can write it to the standard output:" << std::endl;

    digraphWriter(g).                   // write g to the standard output
        nodeMap("label", nodeLabel).    
        nodeMap("supply", supply).
        nodeMap("name", name).
        nodeMap("potential",  potential).

        node("source", source).             // write s to 'source'
        node("target", target).             // write t to 'target'

        arcMap("label", arcLabel).
        arcMap("capacity", capacity_upper).       // write cap into 'capacity'
        arcMap("cost", cost).          // write 'cost' for for arcs
        arcMap("flow", flow).          // write 'flow' for for arcs
        run();
    return ;
}

