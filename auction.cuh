#ifndef auction_cuh
#define auction_cuh

#include <fstream>
#include <iostream>
#include <chrono>
#include <cstdlib>
#include <string>
#include <fstream>
#include <cuda_profiler_api.h>

#include <stdio.h>
#include <stdlib.h>
#include <vector>

//todo add debug
//todo add enum for different graph type
//todo add adjacency list type
#define auctionCode 1
#define SIZE 256
#define EDGESIZE 2048
#define DEBUG 1
#define FULLDEBUG 0

//now support matrix
//Edge is not used;
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
class Graph{
	public:
		enum graphType {matrix, fakeEdgeList, edgeList};
	private:
		int numNodes;
		int numEdges;
		int maxCost;
		int maxCapacity;
		int* dedges;
		int* dcost;
		int* dcostRaw;
		int* dflow;
		int* dlb;
		int* drb;
		int* dprice;
		int* dgrow;
		int* dgrowRaw;
		graphType type;

		int* dnode2edge;
	public:
		Graph(graphType htype,int hnumNodes, int hnumEdges, int hmaxCost, int* hedges, int* hcost, int* hlb, int* hrb, int* hgrow){
			type = htype;
			int sizeNodeArray;
			int sizeEdgeArray;
			maxCost = hmaxCost;
			numNodes = hnumNodes;
			numEdges = hnumEdges;
			sizeNodeArray = numNodes;
			sizeEdgeArray = numNodes*numNodes;

			cudaMalloc((void **)&dedges, numEdges*2*sizeof(int));
			cudaMalloc((void **)&dcost, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&dcostRaw, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&dgrow, sizeNodeArray*sizeof(int));
			cudaMalloc((void **)&dgrowRaw, sizeNodeArray*sizeof(int));
			cudaMalloc((void **)&dlb, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&drb, sizeEdgeArray*sizeof(int));

			cudaMalloc((void **)&dprice, sizeNodeArray*sizeof(int));
		
			cudaMalloc((void **)&dflow, sizeEdgeArray*sizeof(int));


			cudaMemcpy(dedges, hedges, numEdges*2*sizeof(int), cudaMemcpyHostToDevice);
	
			cudaMemcpy(dcost, hcost, sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(dcostRaw, hcost, sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemcpy(dgrow, hgrow, sizeNodeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(dgrowRaw, hgrow, sizeNodeArray*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemcpy(dlb, hlb, sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(drb, hrb, sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemset(dprice, 0, sizeNodeArray*sizeof(int));
			cudaMemset(dflow, 0, sizeEdgeArray*sizeof(int));

		}
		Graph(graphType htype,const char* fileName){
			type = htype;
			int *hcost,*hedges,*hgrow,*hrb,*hlb,*hnode2edge;
			int sizeNodeArray;
			int sizeEdgeArray;
			std::cerr << "input file: " << fileName << std::endl;
			std::cerr << "reading...\n";
			char a;
			int fid;
			int aNum;
			std::ifstream inputfile(fileName, std::ios_base::in);
			inputfile >> numNodes >> numEdges >> aNum;
			std::cout << numNodes << "  " << numEdges << "  " << aNum << std::endl;

			if(type == matrix){
				sizeNodeArray = numNodes;
				sizeEdgeArray = numNodes*numNodes;
			}
			if(type == fakeEdgeList){
				sizeNodeArray = numNodes;
				sizeEdgeArray = numEdges;
			}
			hgrow = (int*)malloc(sizeNodeArray*sizeof(int));
			hedges = (int*)malloc(numEdges*2*sizeof(int));
			hrb = (int*)malloc(sizeEdgeArray*sizeof(int));
			hlb = (int*)malloc(sizeEdgeArray*sizeof(int));
			hcost = (int*)malloc(sizeEdgeArray*sizeof(int));
			for(int i = 0; i < aNum; i++){
				inputfile >> a >> fid;
				inputfile >> hgrow[fid-1];
			}
			if(type == matrix){
				std::cerr << "Graph type: matrix\n";
				int ti,tj;
				for(int i = 0; i < numEdges; i++){
					inputfile >> a >> ti >> tj;
					ti--;tj--;
					hedges[i*2] = ti;
					hedges[i*2+1] = tj;
					inputfile >> hlb[ti*numNodes+tj] >> hrb[ti*numNodes+tj] >> hcost[ti*numNodes +tj];
					maxCost = max(hcost[ti*numNodes + tj], maxCost);
					maxCapacity = max(hrb[ti*numNodes + tj], maxCapacity);
				}
			}
			if(type == fakeEdgeList){
				std::cerr << "Graph type: fakeEdgeList\n";
				hnode2edge = (int*)malloc(sizeNodeArray*sizeNodeArray*sizeof(int));
				memset(hnode2edge, 0, sizeNodeArray*sizeNodeArray*sizeof(int));
				int ti, tj;
				for(int i = 0; i < numEdges; i++){
					inputfile >> a >> ti >> tj;
					ti--;tj--;
					hnode2edge[ti*numNodes + tj] = i;
					hedges[i*2] = ti;
					hedges[i*2+1] = tj;
					inputfile >> hlb[i] >> hrb[i] >> hcost[i];
					maxCost = max(hcost[i],maxCost);
					maxCapacity = max(hrb[i], maxCapacity);
				}
				cudaMalloc((void **)&dnode2edge, sizeNodeArray*sizeNodeArray*sizeof(int));
				cudaMemcpy(dnode2edge, hnode2edge, sizeNodeArray*sizeNodeArray*sizeof(int),cudaMemcpyHostToDevice);
				free(hnode2edge);
			}



			cudaMalloc((void **)&dedges, numEdges*2*sizeof(int));
			cudaMalloc((void **)&dcost, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&dcostRaw, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&dgrow, sizeNodeArray*sizeof(int));
			cudaMalloc((void **)&dgrowRaw, sizeNodeArray*sizeof(int));
			cudaMalloc((void **)&dlb, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&drb, sizeEdgeArray*sizeof(int));
			cudaMalloc((void **)&dprice, sizeNodeArray*sizeof(int));
			cudaMalloc((void **)&dflow, sizeEdgeArray*sizeof(int));
			
			cudaMemcpy(dedges, hedges, numEdges*2*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemcpy(dcost, hcost, sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(dcostRaw, hcost, sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemcpy(dgrow, hgrow, sizeNodeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(dgrowRaw, hgrow, sizeNodeArray*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemcpy(dlb, hlb, sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(drb, hrb, sizeEdgeArray*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemset(dprice, 0, sizeNodeArray*sizeof(int));
			cudaMemset(dflow, 0, sizeEdgeArray*sizeof(int));

			free(hgrow);
			free(hedges);
			free(hrb);
			free(hlb);
			free(hcost);
				
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
			if(type == fakeEdgeList){
				cudaFree(dnode2edge);
			}
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
			if(type == matrix){
				dflow[i*numNodes + j] = value;
				return;
			}
			if(type == fakeEdgeList){
				dflow[dnode2edge[i*numNodes+j]] = value;
				return;
			}
		}
		__inline__ __device__ void setCost(int i, int value){
			dcost[i] = value;
			return;
		}
		__device__ void setCost(int i, int j, int value){
			if(type == matrix){
				dcost[i*numNodes + j] = value;
				return;
			}
			if(type == fakeEdgeList){
				dcost[dnode2edge[i*numNodes+j]] = value;
				return;
			}
		}
		__inline__ __device__ void setGrow(int i, int value){
			dgrow[i] = value;
		}
		__device__ void atomicAddGrow(int i, int value){
			atomicAdd(dgrow + i, value);
		}
		__device__ void atomicSubGrow(int i, int value){
			atomicSub(dgrow + i , value);
		}

		__device__ int edge2source(int i){
			return dedges[i*2];
		}
		__device__ int edge2sink(int i){
			return dedges[i*2 + 1];
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
			if(type == matrix){
				return dcost[i*numNodes + j];
			}
			if(type == fakeEdgeList){
				return dcost[dnode2edge[i*numNodes+j]];
			}
			printf("bad access to dcost!!!");
			return 0;
		}
		__inline__ __device__ int atCostRaw(int i){
			return dcostRaw[i];
		}
		__device__ int atCostRaw(int i, int j){
			if(type == matrix){
				return dcostRaw[i*numNodes + j];
			}
			if(type == fakeEdgeList){
				return dcostRaw[dnode2edge[i*numNodes + j]];
			}
			printf("bad access to dcostRaw!!!");
			return 0;
		}
		__device__ int atFlow(int i, int j){
			if(type == matrix){
				return dflow[i*numNodes + j];
			}
			if(type == fakeEdgeList){
				return dflow[dnode2edge[i*numNodes + j]];
			}
			printf("bad access to dflow!!!");
			return 0;
		}
		__device__ int atLb(int i, int j){
			if(type == matrix){
				return dlb[i*numNodes + j];
			}
			if(type == fakeEdgeList){
				return dlb[dnode2edge[i*numNodes + j]];
			}
			printf("bad access to dlb!!!");
			return 0;
		}
		__device__ int atRb(int i, int j){
			if(type == matrix){
				return drb[i*numNodes + j];
			}
			if(type == fakeEdgeList){
				return drb[dnode2edge[i*numNodes + j]];
			}
			printf("bad access to drb!!!");
			return 0;
		}
		__device__ void printGrow(){
			return;	
		}

		__inline__	__device__ int getNodesNum(){
			return numNodes;
		}
		__inline__	__device__ int getEdgesNum(){
			return numEdges;
		}
};


#endif
