/*************************************************************************
  > File Name: test.cpp
  > Author: zhouyuan
  > Mail: 3294207721@qq.com 
  > Created Time: Tue Apr 27 03:17:10 2021
 ************************************************************************/

#include "mcf_auction.h"
#include <stdio.h>
#include "constructor_graph.h"
using namespace mcf;

int main(int argc, char **argv) {
    if (argc < 2) {
        perror("At least one argument");
        exit(1);
    }
    mcfgraph::Graph<SmartDigraph, SmartDigraph::NodeMap<int> , SmartDigraph::NodeMap<std::string>, SmartDigraph::ArcMap<int> , SmartDigraph::Node> a = 
        mcfgraph::makeGraph<SmartDigraph, SmartDigraph::NodeMap<int> ,  SmartDigraph::NodeMap<std::string>, SmartDigraph::ArcMap<int> , SmartDigraph::Node>();
    std::shared_ptr<GraphImpl<SmartDigraph, SmartDigraph::NodeMap<int> , SmartDigraph::NodeMap<std::string>, SmartDigraph::ArcMap<int> , SmartDigraph::Node>> gra = a.impl();
    gra->getGraph(argv[1]);

    MCFAuction<SmartDigraph, SmartDigraph::NodeMap<int>, SmartDigraph::ArcMap<int>, SmartDigraph::NodeIt, SmartDigraph::ArcIt> mcfinstance(gra->g());
    auto status = mcfinstance.upperMap(gra->capacity_upper())
        .costMap(gra->cost())
        .supplyMap(gra->supply())
        .run();

    if (status == MCFAuction<SmartDigraph, SmartDigraph::NodeMap<int>, SmartDigraph::ArcMap<int>, SmartDigraph::NodeIt, SmartDigraph::ArcIt>::ProblemType::OPTIMAL) {
        auto totalcost = mcfinstance.totalCost<int>();
        mcfinstance.flowMap(gra->flow());
        mcfinstance.potentialMap(gra->potential());
    }
    return 0;
}
