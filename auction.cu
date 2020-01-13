#include <cstdlib>
#include <iostream>
#include <string>
#include <fstream>
#include <cuda_profiler_api.h>

#include <stdio.h>
#include <stdlib.h>
#include <vector>

#include <chrono>
#define MAXMY 0x3f3f
#define SIZE 256
#define EDGESIZE 2048
#define DEBUG 1
using namespace std;

__device__ unsigned int justForTest = 0;
__device__ void dcostScalingInit(
		const int costScale,
		const int gdelta,
		const int ledge,
		const int redge,
		const int lnode,
		const int rnode,
		const int* edges,
		const int* costRaw,
		int* cost,
		int* price){
	int ti,tj;
	for(int i = ledge; i < redge; i++){
		ti = edges[i*2 + 0];
		tj = edges[i*2 + j];
		if(costRaw 
}
__global__ void __launch_bounds__(1024, 1)
auction_algorithm_kernel(
		const int knumNodes,
		const int knumEdges,
		const int kthreadNum,

		const int* kedges,
		int* kcost,
		const int* kcostRaw,
		int* kg,
		const int* kgraw,
		const int* klb,
		const int* krb,
		const int* kprice,
		int* kflow){
	const int threadId = threadIdx.x;
#if DEBUG
//	if(threadId == 0){
//		printf("in kernel\n");
//	}
//	printf("threadId: %d\n", threadId);
#endif
	int edgesDivThread;
	int edgesModThread;
	//[edgesl,edgesr) is the range of edges that the thread produre
	int ledges;
	int redges;

	int nodesDivThread;
	int nodesModThread;
	int lnodes;
	int rnodes;

	int totalIteratorNum = 0;
	int iteratorNum = 0;
	int allIterater = 0;
	int tmpa = 0;
	int tmpb = 0;
	int tmpi = 0;
	int scalingFactor = 2;
	int costScale = 9;
	int gdelta = 0;

	int kti;
	int ktj;

	edgesDivThread = knumEdges/kthreadNum;
	edgesModThread = knumEdges%kthreadNum;
	
	if(threadId < edgesModThread){
		ledges = threadId*(edgesDivThread + 1);
		redges = (threadId + 1)*(edgesDivThread + 1);
	}else {
		ledges = threadId*edgesDivThread + edgesModThread;
		redges = (threadId + 1)*edgesDivThread + edgesModThread;
	}
	
	nodesDivThread = knumNodes/kthreadNum;
	nodesModThread = knumNodes%kthreadNum;

	if(threadId < nodesModThread){
		lnodes = threadId*(nodesDivThread + 1);
		rnodes = (threadId + 1)*(nodesDivThread + 1);
	}else{
		lnodes = threadId*nodesDivThread + nodesModThread;
		rnodes = (threadId + 1)*nodesDivThread + nodesModThread;
	}
#if DEBUG
//	printf("threadId: %d, ledges: %d, redges: %d\n", threadId, ledges, redges);
//	__syncthreads();
//	for(int i = ledges; i < redges; i++){
//		kflow[kedges[i*2 + 0] * knumNodes + kedges[i*2 + 1]] = atomicAdd(&justForTest, 1);
//		printf("%d\n", kflow[kedges[i*2 + 0] * knumNodes + kedges[i*2 + 1]]);
//	}
//	__syncthreads();
#endif
	
	while(costScale >= 0){
		int ktmp = 1<<costScale;

		for(int i = ledges; i < redges; i++){
			kti = kedges[i*2 + 0];
			ktj = kedges[i*2 + 1];
			kflow[kti * knumNodes + ktj] = 0;
			if(kcostRaw[kti*knumNodes + ktj] <= C){
				kcost[kti*knumNodes + ktj] = kcostRaw[kti*knumNodes + ktj]/ktmp;
			}
		}
		for(int i = lnodes; i < rnodes; i++){
			kprice[i]*=(1 << gdelta);
		}



	}

		


	if(threadId == 0)
	{
		printf("kenerl end\n");
	}
}

void run_auction(
		int numNodes,
		int numEdges,
		int threadNum,

		int* hedges,
		int* hcost,
		int* hg,
		int* hlb,
		int* hrb,

		int* hflow){
	cout << "start run_auction\n";
	int* dedges;
	int* dcost;
	int* dcostRaw;
	int* dg;
	int* dgraw;
	int* dlb;
	int* drb;

	int* dprice;

	int* dflow;

	cudaMalloc((void **)&dedges, EDGESIZE*2*sizeof(int));
	cudaMalloc((void **)&dcost, SIZE*SIZE*sizeof(int));
	cudaMalloc((void **)&dcostRaw, SIZE*SIZE*sizeof(int));
	cudaMalloc((void **)&dg, SIZE*sizeof(int));
	cudaMalloc((void **)&dgraw, SIZE*sizeof(int));
	cudaMalloc((void **)&dlb, SIZE*SIZE*sizeof(int));
	cudaMalloc((void **)&drb, SIZE*SIZE*sizeof(int));

	cudaMalloc((void **)&dprice, SIZE*sizeof(int));

	cudaMalloc((void **)&dflow, SIZE*SIZE*sizeof(int));


	cudaMemcpy(dedges, hedges, EDGESIZE*2*sizeof(int), cudaMemcpyHostToDevice);
	
	cudaMemcpy(dcost, hcost, SIZE*SIZE*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dcostRaw, hcost, SIZE*SIZE*sizeof(int), cudaMemcpyHostToDevice);

	cudaMemcpy(dg, hg, SIZE*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dgraw, hg, SIZE*sizeof(int), cudaMemcpyHostToDevice);

	cudaMemcpy(dlb, hlb, SIZE*SIZE*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(drb, hrb, SIZE*SIZE*sizeof(int), cudaMemcpyHostToDevice);

	cudaProfilerStart();
	cout << "start kernel\n";
	auction_algorithm_kernel<<<1,threadNum>>>
		(
		numNodes,
		numEdges,
		threadNum,
		dedges,
		dcost,
		dcostRaw,
		dg,
		dgraw,
		dlb,
		drb,
		dprice,
		dflow);
	cudaProfilerStop();
	cudaDeviceSynchronize();

	cudaMemcpy(hflow, dflow, SIZE*SIZE*sizeof(int), cudaMemcpyDeviceToHost);
	
	int ans = 0;
	for(int i = 0; i < numNodes; i++){
		for(int j = 0; j < numNodes; j++){
//			ans += hflow[i*numNodes + j]*hcost[i*numNodes+ j];
//			cout << hflow[i*numNodes + j] << " ";
		}
	}
	cout << "ans:  " << ans << endl;

}


void initmy(
		int *edges,
		int *cost,
		int *hg,
		int *lb,
		int *rb){
	cout << "start read in graph..\n";
	int tnumNodes;
	int tCapacity = 0;
	int tmaxCost = 0;
	cin >> tnumNodes;
	memset(cost, MAXMY, sizeof(cost));
	memset(edges, 0, sizeof(edges));
	memset(hg, 0, sizeof(hg));
	char a;
	int fid;
	int aNUm;
	cin >> aNUm;
//	cout << "aNUm " << aNUm << endl;
	for(int i = 0; i < aNUm; i++){
		cin >> a >> fid;
		cin >> hg[fid-1];
//		cout << a << " " << fid << " " << g[fid-1] << endl;
	}
	int ti,tj;
	int edgeNum = 0;
	while(true){
		cin >> a >> ti >> tj;
		if(ti == tj&&ti==0){
			break;
		}
		ti--;tj--;
		edges[edgeNum*2] = ti;
		edges[edgeNum*2 + 1] = tj;
		edgeNum++;

		cin >> lb[ti*SIZE + tj] >> rb[ti*SIZE + tj] >>  cost[ti*SIZE + tj] ;
//		cout << a << "\t" << ti << " " << tj << " " << cost[ti*SIZE + tj] <<" " << lb[ti*SIZE + tj] << " " << rb[ti*SIZE + tj] <<  endl;
//		cost[ti][tj] *= nodeNum;
//		cost[ti][tj] %= 4000;
		tmaxCost = max(cost[ti*SIZE + tj], tmaxCost);
		tCapacity = max(rb[ti*SIZE + tj], tCapacity);
	}
	cout << "read end\n";
}

int main(int argc, char *argv[]){
	int threadNum = 1024;
	int numNodes = SIZE;
	int numEdges = EDGESIZE;
	int *hedges = new int[EDGESIZE*2];
	int *hcost = new int[SIZE*SIZE];
	int *hg = new int[SIZE];
	int *hlb = new int[SIZE*SIZE];
	int *hrb = new int[SIZE*SIZE];

	int *hflow = new int[SIZE*SIZE];
	memset(hflow, 0, sizeof(hflow));

	initmy(
		hedges,
		hcost,
		hg,
		hlb,
		hrb
	);

	run_auction(
		numNodes,
		numEdges,
		threadNum,

		hedges,
		hcost,
		hg,
		hlb,
		hrb,

		hflow
	);
	return 0;
}
