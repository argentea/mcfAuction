/*************************************************************************
	> File Name: mcf_auction.h
	> Author: zhouyuan
	> Mail: 3294207721@qq.com 
	> Created Time: Tue Apr 27 06:06:50 2021
 ************************************************************************/

#ifndef _MCF_AUCTION_H
#define _MCF_AUCTION_H

#include "graph.h"
#include "min_cost_flow_gpu.h"
#include <lemon/network_simplex.h>
#include <cstring>
using namespace mcfgpu;
using namespace mcfgraph;

namespace mcf{

template <class G, class NM, class AM, class NI, class AI>
class MCFAuction{
public:
    MCFAuction(G &gra):_gra(gra){
        numNodes = countNodes(_gra);
        numEdges = countArcs(_gra);
        res.flowMap = new int[numEdges]{};
        res.potential = new int[numNodes]{};
    };

     enum ProblemType {
      INFEASIBLE = 0,
      OPTIMAL = 1,
      UNBOUNDED = 2
    };

    ~MCFAuction() {
        delete[] res.flowMap;
        delete[] res.potential;
    }
private:
    Result res;
    G &_gra;
    NM *_supply;
    AM *_capacity_upper;  
    AM *_cost;
    int numNodes, numEdges;
public:
    MCFAuction<G, NM, AM, NI, AI>& supplyMap(NM *supply) {
        this->_supply = supply;
        return *this;
    }

    MCFAuction<G, NM, AM, NI, AI>& upperMap(AM *capacity_upper) {
        this->_capacity_upper = capacity_upper;
        return *this;
    }

    MCFAuction<G, NM, AM, NI, AI>& costMap(AM *cost) {
        this->_cost = cost;
        return *this;
    }
    
    
    auto run() {
        GPU<G, NM, AM, NI, AI> gpu(_gra, _supply, _capacity_upper, _cost);
        gpu.run();
        result temp = gpu.getResult();
        memcpy(res.flowMap, temp.flowMap, sizeof(int) * numEdges);
        memcpy(res.potential, temp.potential, sizeof(int) * numNodes);
        res.pt = temp.pt;
        res.totalCost = temp.totalCost;

       
        switch(res.pt) { 
            case 0: std::cout << "statue is INFEASIBLE" << std::endl; break;
            case 1: std::cout << "statue is OPTIMAL" << std::endl; break;
            case 2: std::cout << "statue is UNBOUNDED" << std::endl; break;
        }
        return res.pt;
    }

    
    template<typename T>
    T totalCost() {
        std::cout << "calculate totalCost is " << res.totalCost <<  std::endl;
        return res.totalCost;
    }


    //check flow
    //template<typename T>
    void flowMap(AM *flow) {
        int totalCalFlow = 0, totalTestFlow = 0, ans = numEdges - 1;
        int flag = 1;
        for (AI arc(_gra); arc != INVALID; ++arc, --ans) {
            totalTestFlow += (*flow)[arc];
            totalCalFlow += res.flowMap[ans];

           if ((*flow)[arc] != res.flowMap[ans]) {
                std::cout << "arc[" << ans << " ] :" << "flow have problem!, test flow is " << (*flow)[arc] << ", calculate flow is " << res.flowMap[ans] << std::endl;
                break;
            }
        
        }
        flag && std::cout << "flow check is success" << std::endl;
        std::cout << "totalTestFlow:: " << totalTestFlow  << ", totalCalFlow :: " << totalCalFlow << std::endl;   
        return ;
    }

    //check potential
    void potentialMap(NM *potential) {
        int totalCalPrice = 0;
        int totalTestPrice = 0;
        int ans = numNodes - 1;
        int flag = 1;
        for (NI n(_gra); n != INVALID; ++n, --ans) {
            totalTestPrice += (*potential)[n];
            totalCalPrice += res.potential[ans];

            if ((*potential)[n] != res.potential[ans]) {
                std:: cout <<"potential[" << ans << "] :"<< "potential have problem!, test potential is " << (*potential)[n] << ", calculate potential is " << res.potential[ans]<< std::endl;
                flag = 0;
                break;
            }
        }
        flag && std::cout << "potential  check is success" << std::endl;
        std::cout << "totalTestPrice : " << totalTestPrice << " , totalCalPrice : " << totalCalPrice << std:: endl;
        return ;
    }
};

};//namespace mcf end;

#endif
