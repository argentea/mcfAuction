/*************************************************************************
	> File Name: smartdigraph.h
	> Author: zhouyuan
	> Mail: 3294207721@qq.com 
	> Created Time: Thu Apr 22 04:01:36 2021
 ************************************************************************/

#ifndef _SMARTDIGRAPH_H
#define _SMARTDIGRAPH_H
#include<iostream>
#include <lemon/smart_graph.h>
#include <lemon/lgf_reader.h>
#include <lemon/lgf_writer.h>
#include <lemon/capacity_scaling.h>
#include "graph.h"
//using namespace lemon;
using namespace mcfgraph;
void getSmartDigraph(const char* fileName, std::shared_ptr<GraphImpl> a);
#endif
