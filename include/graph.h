/*************************************************************************
	> File Name: graph.h
	> Author: zhouyuan
	> Mail: 3294207721@qq.com 
	> Created Time: Sun Apr 25 05:56:14 2021
 ************************************************************************/

#ifndef _GRAPH_H
#define _GRAPH_H
#include <lemon/smart_graph.h>
using namespace lemon;

namespace mcfgraph {

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

    SmartDigraph &g() { return _g; }
    SmartDigraph::NodeMap<int> *nodeLabel(){ return &_nodeLabel; }
    SmartDigraph::NodeMap<int> *supply(){ return &_supply; }
    SmartDigraph::NodeMap<std::string> *name(){ return &_name; }
    SmartDigraph::NodeMap<int> *potential(){ return &_potential; }
    SmartDigraph::ArcMap<int> *arcLabel(){ return &_arcLabel; }
    SmartDigraph::ArcMap<int> *capacity_upper(){ return &_capacity_upper; }
    SmartDigraph::ArcMap<int> *cost(){ return &_cost; }
    SmartDigraph::ArcMap<int> *flow(){ return &_flow; }
    SmartDigraph::Node *source(){ return &_source; }
    SmartDigraph::Node *target(){ return &_target; }
    
private:
    SmartDigraph _g;
    SmartDigraph::NodeMap<int> _nodeLabel;
    SmartDigraph::NodeMap<int> _supply;
    SmartDigraph::NodeMap<std::string> _name;
    SmartDigraph::NodeMap<int> _potential;
    SmartDigraph::ArcMap<int> _arcLabel;
    SmartDigraph::ArcMap<int> _capacity_upper;
    SmartDigraph::ArcMap<int> _cost;
    SmartDigraph::ArcMap<int> _flow;
    SmartDigraph::Node _source;
    SmartDigraph::Node _target;
};


};

#endif
