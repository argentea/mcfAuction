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

template<class G, class NMI, class NMS, class AM, class N>
class Graph {
private:
    std::shared_ptr<GraphImpl<G, NMI, NMS, AM, N>> impl_;
public:
    Graph(std::shared_ptr<GraphImpl<G, NMI, NMS, AM, N>> impl):impl_(std::move(impl)){}
    auto impl() { 
        return impl_; 
    }
};

template<typename G, typename NMI, typename NMS, typename AM, typename N>
auto makeGraph(){ 
    return Graph<G, NMI, NMS, AM, N>(std::make_shared<GraphImpl<G, NMI, NMS, AM, N>>()); 
}

};

#endif
