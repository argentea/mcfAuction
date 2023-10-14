#ifndef auction_cuh
#define auction_cuh

#include <fstream>
#include <iostream>
#include <chrono>
#include <cstdlib>
#include <string>
#include <fstream>
#include <cuda_profiler_api.h>
#include <lemon/smart_graph.h>
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include "graph.h"

using namespace lemon;
using namespace mcfgraph;

//todo add debug
//todo add enum for different graph type
//todo add adjacency list type
#define DEBUG 1
#define DEBUG1 1
#define FULLDEBUG 1

//now support matrix
//Edge is not used;

namespace mcfgpu{

typedef std::chrono::high_resolution_clock::rep hr_clock_rep;

inline hr_clock_rep get_globaltime(void) 
{
	using namespace std::chrono;
	return high_resolution_clock::now().time_since_epoch().count();
}

// Returns the period in miliseconds
inline double get_timer_period(void) 
{
	using namespace std::chrono;
	return 1000.0 * high_resolution_clock::period::num / high_resolution_clock::period::den;
}
template <class G, class NM, class AM, class NI, class AI>
class Graph{
	public:
		enum graphType {matrix, edgeList};
        struct Edge 
        {
            int source; 
            int sink; 
        };

	private:
		int numNodes;
		int numEdges;
		int maxCost;
#define auctionCode 1
		int maxCapacity;
		Edge* dedges;
		int* dcost;
		int* dcostRaw;
		int* dflow;
		int* dlb;
		int* drb;
		int* dprice;
		int* dgrow;
		int* dgrowRaw;
        int totalCost = 0;
		graphType type;

	public:
		Graph(graphType htype,int hnumNodes, int hnumEdges, int hmaxCost, 
                const Edge* hedges, const int* hcost, const int* hlb, const int* hrb, const int* hgrow){
			type = htype;
			int sizeNodeArray = 0;
			int sizeEdgeArray = 0;
			maxCost = hmaxCost;
			numNodes = hnumNodes;
			numEdges = hnumEdges;
			sizeNodeArray = numNodes;
			sizeEdgeArray = numNodes*numNodes;

			cudaMalloc((void **)&dedges, numEdges*sizeof(Edge));
			cudaMalloc((void **)&dcost, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&dcostRaw, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&dgrow, sizeNodeArray*sizeof(int));
			cudaMalloc((void **)&dgrowRaw, sizeNodeArray*sizeof(int));
			cudaMalloc((void **)&dlb, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&drb, sizeEdgeArray*sizeof(int));

			cudaMalloc((void **)&dprice, sizeNodeArray*sizeof(int));
		
			cudaMalloc((void **)&dflow, sizeEdgeArray*sizeof(int));


			cudaMemcpy(dedges, hedges, numEdges*sizeof(Edge), cudaMemcpyHostToDevice);
	
			cudaMemcpy(dcost, hcost, sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(dcostRaw, hcost, sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemcpy(dgrow, hgrow, sizeNodeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(dgrowRaw, hgrow, sizeNodeArray*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemcpy(dlb, hlb, sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(drb, hrb, sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemset(dprice, 0, sizeNodeArray*sizeof(int));
			cudaMemset(dflow, 0, sizeEdgeArray*sizeof(int));

		}
		Graph(
                graphType htype, 
                G &map, 
                NM *supply, 
                AM *capacity_uppper,
                AM *cost)
        {
			type = htype;
			int sizeNodeArray = 0;
			int sizeEdgeArray = 0;
            numNodes = countNodes(map);
            numEdges = countArcs(map);
            
            if(type == matrix){
				sizeNodeArray = numNodes;
				sizeEdgeArray = numNodes * numNodes;
			}
			if(type == edgeList){
				sizeNodeArray = numNodes;
				sizeEdgeArray = numEdges;
			}

            std::vector<int> hgrow (sizeNodeArray); //
            std::vector<Edge> hedges (numEdges); 
            std::vector<int> hrb (sizeEdgeArray); 
            std::vector<int> hlb (sizeEdgeArray); 
            std::vector<int> hcost (sizeEdgeArray); 
            
            
            for (NI n(map); n != INVALID; ++n) {
                int cnt = map.id(n);
                hgrow[cnt] = (*supply)[n];
            }

            for (AI arc(map); arc != INVALID; ++arc) {
                int cnt = map.id(arc);
                int sta = map.id(map.source(arc));
                int end = map.id(map.target(arc)); 
                hedges[cnt].source = sta;
                hedges[cnt].sink = end;
                if (type == edgeList) {
                    hlb[cnt] = 0;
                    hrb[cnt] = (*capacity_uppper)[arc];
                    hcost[cnt] = (*cost)[arc];
                    totalCost += hcost[cnt];
				    maxCost = max(hcost[cnt],maxCost);
				    maxCapacity = max(hrb[cnt], maxCapacity);
                }

                if (type == matrix){
				    hlb[sta * numNodes + end] = 0;
                    hrb[sta * numNodes + end]  = (*capacity_uppper)[arc];
                    hcost[sta * numNodes + end] = (*cost)[arc];
				    maxCost = max(hcost[sta * numNodes + end], maxCost);
				    maxCapacity = max(hrb[sta * numNodes + end], maxCapacity);
                }
            }
			cudaMalloc((void **)&dedges, numEdges*sizeof(Edge));
			cudaMalloc((void **)&dcost, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&dcostRaw, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&dgrow, sizeNodeArray*sizeof(int));
			cudaMalloc((void **)&dgrowRaw, sizeNodeArray*sizeof(int));
			cudaMalloc((void **)&dlb, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&drb, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&dprice, sizeNodeArray*sizeof(int));
			cudaMalloc((void **)&dflow, sizeEdgeArray*sizeof(int));
			
			cudaMemcpy(dedges, hedges.data(), numEdges*sizeof(Edge), cudaMemcpyHostToDevice);

			cudaMemcpy(dcost, hcost.data(), sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(dcostRaw, hcost.data(), sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemcpy(dgrow, hgrow.data(), sizeNodeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(dgrowRaw, hgrow.data(), sizeNodeArray*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemcpy(dlb, hlb.data(), sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(drb, hrb.data(), sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemset(dprice, 0, sizeNodeArray*sizeof(int));
			cudaMemset(dflow, 0, sizeEdgeArray*sizeof(int));

			std::cerr << "read end\n";
		}
		~Graph(){
			cudaFree(dedges);
			cudaFree(dcost);
			cudaFree(dcostRaw);
			cudaFree(dgrow);
			cudaFree(dgrowRaw);
			cudaFree(dlb);
			cudaFree(drb);
			cudaFree(dprice);
			cudaFree(dflow);
            
		}
		__device__ int getMaxCost(){
			return maxCost;
		}
		__device__ void setPrice(int i, int value){
			dprice[i] = value;
		}
		__inline__ __device__ void setFlow(int i, int value){
			dflow[i] = value;
			return;
		}
		__device__ void setFlow(int i, int j ,int value){
			dflow[i*numNodes + j] = value;
			return;
		}
		__inline__ __device__ void setCost(int i, int value){
			dcost[i] = value;
			return;
		}
		__device__ void setCost(int i, int j, int value){
			dcost[i*numNodes + j] = value;
			return;
		}
		__inline__ __device__ void setGrow(int i, int value){
			dgrow[i] = value;
		}
		__device__ int atomicAddGrow(int i, int value){
			return atomicAdd(dgrow + i, value);
		}
		__device__ int atomicSubGrow(int i, int value){
			return atomicSub(dgrow + i , value);
		}

    __device__ Edge const& edge(int i) const {
        return dedges[i];
    }
		__device__ int edge2source(int i){
			return dedges[i].source;
		}
		__device__ int edge2sink(int i){
			return dedges[i].sink;
		}
		
		__device__ int atPrice(int i){
			return dprice[i];
		}
		__device__ int atGrow(int i){
			return dgrow[i];
		}
		__device__ int atGrowRaw(int i){
			return dgrowRaw[i];
		}
		__inline__ __device__ int atCost(int i){
			return dcost[i];
		}
		__device__ int atCost(int i, int j){
			return dcost[i*numNodes + j];
		}
        
        int *getFlow() {
            return dflow;
        }
		__inline__ __device__ int atCostRaw(int i){
			return dcostRaw[i];
		}
		__device__ int atCostRaw(int i, int j){
			return dcostRaw[i*numNodes + j];
		}
		__inline__ __device__ int atFlow(int i){
			return dflow[i];
		}
		__device__ int atFlow(int i, int j){
			return dflow[i*numNodes + j];
		}
		__inline__ __device__ int atLb(int i){
			return dlb[i];
		}
		__device__ int atLb(int i, int j){
			return dlb[i*numNodes + j];
		}
		__inline__ __device__ int atRb(int i){
			return drb[i];
		}
		__device__ int atRb(int i, int j){
			return drb[i*numNodes + j];
		}
		//Todo add printGraph function
		__device__ void printGrow(){
			for(int i = 0; i < numNodes; i++){
				printf("%d\t", dgrow[i]);
			}
			printf("\n");
			return;	
		}

		__inline__	__host__ __device__ int getNodesNum() const {
			return numNodes;
		}
		__inline__	__host__ __device__ int getEdgesNum() const {
			return numEdges;
		}
};

};

#endif
