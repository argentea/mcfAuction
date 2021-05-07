/*************************************************************************
	> File Name: min_cost_flow_gpu.h
	> Author: zhouyuan
	> Mail: 3294207721@qq.com 
	> Created Time: Mon Apr 26 07:00:49 2021
 ************************************************************************/

#ifndef _MIN_COST_FLOW_GPU_H
#define _MIN_COST_FLOW_GPU_H

#include <lemon/smart_graph.h>
#include <stdlib.h>
using namespace lemon;
namespace mcfgpu{


enum ProblemType {
      INFEASIBLE = 0,
      OPTIMAL = 1,
      UNBOUNDED = 2
};
    
typedef struct result{
    ProblemType pt;
    int totalCost;
    int *flowMap;
    int *potential;
    
} Result;

class Graph;
class GPU{
public:
    GPU( 
        SmartDigraph &map, 
        SmartDigraph::NodeMap<int> *supply,
        SmartDigraph::ArcMap<int> *capacity_upper,
        SmartDigraph::ArcMap<int> *cost):
        _map(map),
        _supply(supply),
        _capacity_upper(capacity_upper),
        _cost(cost){
            numNodes = countNodes(map);
            numEdges = countArcs(map);
            res.flowMap = new int(numEdges);
            res.potential = new int(numNodes);
        }

    Result run();
  // int totalCost() { }


   void setFlow(int i, int value) {
        res.flowMap[i] = value;
   }

 //   int potentialMap() {}
    ~GPU(){
        delete[] res.flowMap;
        delete[] res.potential;
    }
private:
    ProblemType run_auction(Graph auctionGraph, int threadNum);
    SmartDigraph &_map;
    SmartDigraph::NodeMap<int> *_supply;
    SmartDigraph::ArcMap<int> *_capacity_upper;
    SmartDigraph::ArcMap<int> *_cost;
    int numNodes;
    int numEdges;
    Result res;
};
};
#endif
