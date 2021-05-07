/*************************************************************************
	> File Name: constructor_graph.h
	> Author: zhouyuan
	> Mail: 3294207721@qq.com 
	> Created Time: Sun Apr 25 02:40:12 2021
 ************************************************************************/

#ifndef _CONSTRUCTOR_GRAHP_H
#define _CONSTRUCTOR_GRAPH_H
#include "graph.h"
#include <memory>
namespace mcfgraph {

class Graph {
private:
    std::shared_ptr<GraphImpl> impl_;
public:
    Graph(std::shared_ptr<GraphImpl> impl):impl_(std::move(impl)){}
    auto impl() { 
        return impl_; 
    }
};

auto makeGraph(){ 
    return Graph(std::make_shared<GraphImpl>()); 
}

};

#endif
