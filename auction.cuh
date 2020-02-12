#ifndef auction_cuh
#define auction_cuh

#include <stdio.h>
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
class Edge{
	private:
		int source;
		int sink;
	public:
		Edge(int so, int si):source(so),sink(si){}
		int sourceAt(){
			return source;
		}
		int sinkAt(){
			return sink;
		}
};
class Graph{
	public:
		enum graphType {matrix, edgePriority, vetexPriority};
	private:
		int numNodes;
		int numEdges;
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
	public:
		Graph(int hnumNodes, int hnumEdges, int* hedges, int* hcost, int* hlb, int* hrb, int* hgrow){
			type = matrix;
			numNodes = hnumNodes;
			numEdges = hnumEdges;
			cudaMalloc((void **)&dedges, EDGESIZE*2*sizeof(int));
			cudaMalloc((void **)&dcost, SIZE*SIZE*sizeof(int));
			cudaMalloc((void **)&dcostRaw, SIZE*SIZE*sizeof(int));
			cudaMalloc((void **)&dgrow, SIZE*sizeof(int));
			cudaMalloc((void **)&dgrowRaw, SIZE*sizeof(int));
			cudaMalloc((void **)&dlb, SIZE*SIZE*sizeof(int));
			cudaMalloc((void **)&drb, SIZE*SIZE*sizeof(int));

			cudaMalloc((void **)&dprice, SIZE*sizeof(int));
		
			cudaMalloc((void **)&dflow, SIZE*SIZE*sizeof(int));


			cudaMemcpy(dedges, hedges, EDGESIZE*2*sizeof(int), cudaMemcpyHostToDevice);
	
			cudaMemcpy(dcost, hcost, SIZE*SIZE*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(dcostRaw, hcost, SIZE*SIZE*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemcpy(dgrow, hgrow, SIZE*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(dgrowRaw, hgrow, SIZE*sizeof(int), cudaMemcpyHostToDevice);

			cudaMemcpy(dlb, hlb, SIZE*SIZE*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(drb, hrb, SIZE*SIZE*sizeof(int), cudaMemcpyHostToDevice);
			cudaMemset(dprice, 0, SIZE*sizeof(int));
			cudaMemset(dflow, 0, SIZE*SIZE*sizeof(int));

		}
		~Graph(){
			cudaFree(dedges);
			cudaFree(dcost);
			cudaFree(dcostRaw);
			cudaFree(dgrow);
			cudaFree(dgrowRaw);
			cudaFree(dlb);
			cudaFree(drb);
		}
		__device__ void chagePrice(int i, int value){
			dprice[i] = value;
		}
		__device__ void chageFlow(int i, int j ,int value){
			dflow[i*numNodes + j] = value;
		}
		__device__ void chageGrow(int i, int value){
			dgrow[i] = value;
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

		__device__ int getNodesNum(){
			return numNodes;
		}
		__device__ int getEdgesNum(){
			return numEdges;
		}
};


#endif
