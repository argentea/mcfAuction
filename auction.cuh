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
		enum graphType {matrix, edgePriority, vetexPriority};
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

		int* node2edge;
	public:
		Graph(graphType htype,int hnumNodes, int hnumEdges, int hmaxCost, int* hedges, int* hcost, int* hlb, int* hrb, int* hgrow){
			type = htype;
			if(type == matrix){
			maxCost = hmaxCost;
			numNodes = hnumNodes;
			numEdges = hnumEdges;
			cudaMalloc((void **)&dedges, numEdges*2*sizeof(int));
			cudaMalloc((void **)&dcost, numNodes*numNodes*sizeof(int));
			cudaMalloc((void **)&dcostRaw, numNodes*numNodes*sizeof(int));
			cudaMalloc((void **)&dgrow, numNodes*sizeof(int));
			cudaMalloc((void **)&dgrowRaw, numNodes*sizeof(int));
			cudaMalloc((void **)&dlb, numNodes*numNodes*sizeof(int));
			cudaMalloc((void **)&drb, numNodes*numNodes*sizeof(int));

			cudaMalloc((void **)&dprice, numNodes*sizeof(int));
		
			cudaMalloc((void **)&dflow, numNodes*numNodes*sizeof(int));


			cudaMemcpy(dedges, hedges, numEdges*2*sizeof(int), cudaMemcpyHostToDevice);
	
			cudaMemcpy(dcost, hcost, numNodes*numNodes*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(dcostRaw, hcost, numNodes*numNodes*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemcpy(dgrow, hgrow, numNodes*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(dgrowRaw, hgrow, numNodes*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemcpy(dlb, hlb, numNodes*numNodes*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(drb, hrb, numNodes*numNodes*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemset(dprice, 0, numNodes*sizeof(int));
			cudaMemset(dflow, 0, numNodes*numNodes*sizeof(int));
			}

		}
		Graph(graphType type,const char* fileName){
			if(type == matrix){
				std::cerr << "Graph type: matrix\n";
				std::cerr << "input file: " << fileName << std::endl;
				std::cerr << "reading...\n";
				int *hcost,*hedges,*hgrow,*hrb,*hlb;
				char a;
				int fid;
				int aNum;
				std::ifstream inputfile(fileName, std::ios_base::in);
				inputfile >> numNodes >> numEdges >> aNum;
				std::cout << numNodes << "  " << numEdges << "  " << aNum << std::endl;
				hgrow = (int*)malloc(numNodes*sizeof(int));
				hedges = (int*)malloc(numEdges*2*sizeof(int));
				hrb = (int*)malloc(numNodes*numNodes*sizeof(int));
				hlb = (int*)malloc(numNodes*numNodes*sizeof(int));
				hcost = (int*)malloc(numNodes*numNodes*sizeof(int));
				for(int i = 0; i < aNum; i++){
					inputfile >> a >> fid;
					inputfile >> hgrow[fid-1];
				}
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
				cudaMalloc((void **)&dedges, numEdges*2*sizeof(int));
				cudaMalloc((void **)&dcost, numNodes*numNodes*sizeof(int));
				cudaMalloc((void **)&dcostRaw, numNodes*numNodes*sizeof(int));
				cudaMalloc((void **)&dgrow, numNodes*sizeof(int));
				cudaMalloc((void **)&dgrowRaw, numNodes*sizeof(int));
				cudaMalloc((void **)&dlb, numNodes*numNodes*sizeof(int));
				cudaMalloc((void **)&drb, numNodes*numNodes*sizeof(int));
				cudaMalloc((void **)&dprice, numNodes*sizeof(int));
				cudaMalloc((void **)&dflow, numNodes*numNodes*sizeof(int));
				
				cudaMemcpy(dedges, hedges, numEdges*2*sizeof(int), cudaMemcpyHostToDevice);
	
				cudaMemcpy(dcost, hcost, numNodes*numNodes*sizeof(int), cudaMemcpyHostToDevice);
				cudaMemcpy(dcostRaw, hcost, numNodes*numNodes*sizeof(int), cudaMemcpyHostToDevice);

				cudaMemcpy(dgrow, hgrow, numNodes*sizeof(int), cudaMemcpyHostToDevice);
				cudaMemcpy(dgrowRaw, hgrow, numNodes*sizeof(int), cudaMemcpyHostToDevice);

				cudaMemcpy(dlb, hlb, numNodes*numNodes*sizeof(int), cudaMemcpyHostToDevice);
				cudaMemcpy(drb, hrb, numNodes*numNodes*sizeof(int), cudaMemcpyHostToDevice);
				cudaMemset(dprice, 0, numNodes*sizeof(int));
				cudaMemset(dflow, 0, numNodes*numNodes*sizeof(int));

				free(hgrow);
				free(hedges);
				free(hrb);
				free(hlb);
				free(hcost);
				
				std::cerr << "read end\n";
			}
			if(type == 

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
		__device__ void setFlow(int i, int j ,int value){
			dflow[i*numNodes + j] = value;
		}
		__device__ void setCost(int i, int j, int value){
			dcost[i*numNodes + j] = value;
		}
		__device__ void setGrow(int i, int value){
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
		__device__ int atCost(int i, int j){
			return dcost[i*numNodes + j];
		}
		__device__ int atCostRaw(int i, int j){
			return dcostRaw[i*numNodes + j];
		}
		__device__ int atFlow(int i, int j){
			return dflow[i*numNodes + j];
		}
		__device__ int atLb(int i, int j){
			return dlb[i*numNodes + j];
		}
		__device__ int atRb(int i, int j){
			return drb[i*numNodes + j];
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
