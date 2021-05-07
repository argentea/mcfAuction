/*************************************************************************
	> File Name: test.cpp
	> Author: zhouyuan
	> Mail: 3294207721@qq.com 
	> Created Time: Tue Apr 27 03:17:10 2021
 ************************************************************************/

#include "mcf_auction.h"
#include "smartdigraph.h"
#include "constructor_graph.h"
#include <stdio.h>
using namespace mcf;
int main(int argc, char **argv) {
    if (argc < 2) {
        perror("At least one argument");
        exit(1);
    }
    mcfgraph::Graph a = mcfgraph::makeGraph();
    std::shared_ptr<GraphImpl> gra = a.impl();
    getSmartDigraph(argv[1], gra);
    
    MCFAuction mcf(gra->g());
    auto status = mcf.upperMap(gra->capacity_upper())
        .costMap(gra->cost())
        .supplyMap(gra->supply())
        .run();
    if (status == MCFAuction::ProblemType::OPTIMAL) {
        auto totalcost = mcf.template totalCost<int>();
        mcf.flowMap(gra->flow());
        mcf.potentialMap(gra->potential());
    }
    return 0;
}
