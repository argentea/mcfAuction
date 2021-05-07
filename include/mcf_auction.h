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

using namespace std;
using namespace mcfgpu;
using namespace mcfgraph;

extern "C" void run();
namespace mcf{

class MCFAuction{
public:
    MCFAuction(SmartDigraph &gra):_gra(gra){};

     enum ProblemType {
      INFEASIBLE = 0,
      OPTIMAL = 1,
      UNBOUNDED = 2
    };

    /*void cpu(){
        CPU cpu = CPU(gra, gdebug);
        cpu.run();
        return ;
   }
   */
   //  mcfgpu::ProblemType gpu() {}
    ~MCFAuction() {}
private:
    Result res;
    SmartDigraph &_gra;
    SmartDigraph::NodeMap<int> *_supply;
    SmartDigraph::ArcMap<int> *_capacity_upper;  
    SmartDigraph::ArcMap<int> *_cost;
public:
    MCFAuction& supplyMap(SmartDigraph::NodeMap<int> *supply) {
        this->_supply = supply;
        return *this;
    }

    MCFAuction& upperMap(SmartDigraph::ArcMap<int> *capacity_upper) {
        this->_capacity_upper = capacity_upper;
        return *this;
    }

    MCFAuction& costMap(SmartDigraph::ArcMap<int> *cost) {
        this->_cost = cost;
        return *this;
    }
    
    template<typename T>
    T totalCost() {
        std::cout << "calculate totalCost is " << res.totalCost <<  std::endl;
        return res.totalCost;
    }

    void flowMap(SmartDigraph::ArcMap<int> *flow) {
        int totalCalFlow = 0, totalTestFlow = 0;
        int *testSupply = new int(countNodes(_gra));
        for (SmartDigraph::ArcIt arc(_gra); arc != INVALID; ++arc) {
            int ans = _gra.id(arc);
            totalTestFlow += (*flow)[arc];
            totalCalFlow += res.flowMap[ans];
            
            testSupply[_gra.id(_gra.source(arc))] += res.flowMap[ans];
            testSupply[_gra.id(_gra.target(arc))] -= res.flowMap[ans];
            std::cout <<  "calculate flow[" << ans << "] is " << res.flowMap[ans] << std::endl;
        }


        for (SmartDigraph::NodeIt n(_gra); n != INVALID; ++n) {
            if ((*_supply)[n] != testSupply[_gra.id(n)]) {
                cout << "supply : " << (*_supply)[n] << ", testsupply : " << testSupply[_gra.id(n)] << endl;
            }
            
        }
       //     if ((*flow)[arc] != res.flowMap[ans]) {
         //       std::cout << "arc[" << ans << " ] :" << "flow have problem!, test flow is " << (*flow)[arc] << ", calculate flow is " << res.flowMap[ans] << std::endl;
           //    break;
            //}
        cout<< "totalTestFlow:: " << totalTestFlow  << ", totalCalFlow :: " << totalCalFlow << endl;

        return ;
    }


    void potentialMap(SmartDigraph::NodeMap<int> *potential) {
        int ans = 1;
        int totalCalPrice = 0;
        int totalTestPrice = 0;
        for (SmartDigraph::NodeIt n(_gra); n != INVALID; ++n, ++ans) {
            totalCalPrice += res.potential[ans];
            totalTestPrice += (*potential)[n];
        }
        //    std::cout << "really potential[" << ans << "] is " <<  res.potential[ans] << std::endl;
            /*if ((*potential)[n] != res.potential[ans]) {
                std:: cout <<"[" << ans << "] :"<< "potential have problem!, test potential is " << (*potential)[n] << ", calculate potential is " << res.potential[ans]<< std::endl;
                break;
            }
            */
            cout << "totalTestPrice : " << totalTestPrice << " , totalCalPrice : " << totalCalPrice <<  endl;
        return ;
    }


    auto run() {
        GPU gpu(_gra, _supply, _capacity_upper, _cost);
        res = gpu.run();
        switch(res.pt) { 
            case 0: cout << "statue is INFEASIBLE" << endl; break;
            case 1: cout << "statue is OPTIMAL" << endl; break;
            case 2: cout << "statue is UNBOUNDED" << endl; break;
        }
        return res.pt;
    }
};

};


#endif
