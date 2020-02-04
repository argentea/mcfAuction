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
#define FULLDEBUG 0
using namespace std;
__device__ int kflag;
__device__ int tans;
__device__ int minRise;
__device__ int kpushListPo[SIZE];
__device__ int kpushListNa[SIZE];
__device__ bool knodesRisePrice[SIZE];
__device__ void kcheck(
		const int* kg,
		int lnodes,
		int rnodes
		){
	for(int i = lnodes; i < rnodes; i++){
		if(kg[i] != 0){
			atomicAnd(&kflag, 0);
		}
	}
	__syncthreads();
}
__device__ void printNodes(const int* nodes, int numNodes, const char* name){
	printf("*******************\n");
	printf(name);
	for(int i = 0; i < numNodes; i++){
		printf("%d\t", nodes[i]);
	}
	printf("\n*******************\n");
}
__device__ void printGraph(const int* graph, int numNodes, const char* name){
	printf("*******************\n");
	printf("%d", numNodes);
	printf(name);
//	for(int i = 0; i < numNodes; i++){
//		for(int j = 0; j < numNodes; j++){
//			printf("%d\t", graph[i*numNodes + j]);
//		}
//		printf("\n");
//	}
	printf("*******************\n");
}

__device__ unsigned int justForTest = 0;
__device__ void dcostScalingInit(
		const int costScale,
		const int gdelta,
		const int C,
		const int ledges,
		const int redges,
		const int lnodes,
		const int rnodes,
		const int knumNodes,
		const int* edges,
		const int* costRaw,
		int* cost,
		int* price){
	int ti,tj;
	for(int i = ledges; i < redges; i++){
		ti = edges[i*2 + 0];
		tj = edges[i*2 + 1];
		if(costRaw[ti*knumNodes + tj] <= C){
			cost[ti*knumNodes + tj] = costRaw[ti*knumNodes + tj]/(1 << costScale);
		}
	}
	for(int i = lnodes; i < rnodes; i++){
		price[i]*=(1 << gdelta);
	}
	return;
}
__device__ void pushFlow(
		const int lnodes,
		const int rnodes,
		const int ledges,
		const int redges,
		const int epsilon,
		const int knumNodes,
		int* kflow,
		const int* krb,
		const int* klb,
		const int* kprice,
		const int* kcost,
		const int* kedges,
		int* kg
		){
	for(int i = lnodes; i < rnodes; i++){
		kpushListPo[i] = -1;
		kpushListNa[i] = -1;
	}
	for(int i = ledges; i < redges; i++){
		int ti,tj;
		ti = kedges[i*knumNodes + 0];
		tj = kedges[i*knumNodes + 1];
		if(kcost[ti*knumNodes + tj] - kprice[ti] + kprice[tj] + epsilon == 0&&kg[ti] >0){
			atomicExch(kpushListPo + ti, tj);
			continue;
		}
		if(kcost[ti*knumNodes + tj] - kprice[ti] + kprice[tj] - epsilon == 0&&kg[tj] > 0){
			atomicExch(kpushListNa + tj, ti);
			continue;
		}
	}
	int delta;
	for(int i = lnodes; i < rnodes; i++){
		if(kpushListPo[i] != -1){
//			delta = min(kg[i], krb[i*knumNodes + kpushListPo[i]] - kflow[i*knumNodes + kpushListPo[i]]);
			kflow[i*knumNodes + kpushListPo[i]] += delta;
			atomicSub(kg+i, delta);
			atomicSub(kg + kpushListPo[i], delta);
		}
	}
	for(int i = lnodes; i < rnodes; i++){
		if(kpushListNa[i] != -1){
//			delta = min(kg[i], kflow[kpushListNa[i]*knumNodes + i]);
			kflow[kpushListNa[i]*knumNodes + i] -= delta;
			atomicSub(kg+i, delta);
			atomicSub(kg + kpushListNa[i], delta);
		}
	}
	return ;
}
__device__ void priceRise(
		const int lnodes,
		const int rnodes,
		const int ledges,
		const int redges,
		const int epsilon,
		const int knumNodes,
		const int* kflow,
		const int* krb,
		const int* klb,
		const int* kprice,
		const int* kcost,
		const int* edges,
		const int* kg
		){
	int ti,tj,swap,tmpa,tmpb;
	for(int i = lnodes; i < rnodes; i++){
		if(kg[i] > 0){
			knodesRisePrice[i] = true;
		}else {
			knodesRisePrice[i] = false;
		}
	}
	for(int i = ledges; i < redges; i++){
		ti = edges[i*2 + 0];
		tj = edges[i*2 + 1];
		if(knodesRisePrice[ti]!=knodesRisePrice[tj]){
			if(knodesRisePrice[tj]){
				swap  = ti;
				ti = tj;
				tj = swap;
			}
			if(kflow[ti*knumNodes + tj] < krb[ti*knumNodes + tj]){
				tmpb = kprice[tj] + kcost[ti*knumNodes + tj] + epsilon - kprice[ti];
				if(tmpb >= 0){
					atomicMax(&minRise, tmpb);
				}
			}
			if(kflow[tj*knumNodes + ti] > klb[tj*knumNodes + ti]){
				tmpa = kprice[tj] - kcost[tj*knumNodes + ti] + epsilon - kprice[ti];
				if(tmpa > 0){
					atomicMax(&minRise, tmpa);
				}
			}
		}
	}
}
__global__ void __launch_bounds__(1024, 1)
auction_algorithm_kernel(
		const int knumNodes,
		const int knumEdges,
		const int kthreadNum,
		const int kC,

		const int* kedges,
		int* kcost,
		const int* kcostRaw,
		int* kg,
		const int* kgraw,
		const int* klb,
		const int* krb,
		int* kprice,
		int* kflow){
	const int threadId = threadIdx.x;

	
	if(threadId == 0){
		printf("in kernel\n");
	}
	__syncthreads();


	int kepsilon = 1;
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
#if FULLDEBUG
	printf("threadId: %d, ledges: %d, redges: %d\n", threadId, ledges, redges);
	__syncthreads();
	for(int i = ledges; i < redges; i++){
		kflow[kedges[i*2 + 0] * knumNodes + kedges[i*2 + 1]] = atomicAdd(&justForTest, 1);
		printf("%d\n", kflow[kedges[i*2 + 0] * knumNodes + kedges[i*2 + 1]]);
	}
	__syncthreads();
#endif
	while(costScale >= 0){

		int ktmp = 1<<costScale;

		for(int i = ledges; i < redges; i++){
			kti = kedges[i*2 + 0];
			ktj = kedges[i*2 + 1];
			kflow[kti * knumNodes + ktj] = 0;
			if(kcostRaw[kti*knumNodes + ktj] <= kC){
				kcost[kti*knumNodes + ktj] = kcostRaw[kti*knumNodes + ktj]/ktmp;
			}
		}
		for(int i = lnodes; i < rnodes; i++){
			kprice[i]*=(1 << gdelta);
		}
		__syncthreads();
		for(int i = ledges; i < redges; i++){
				kti = kedges[i*2 + 0];
				ktj = kedges[i*2 + 1];
				if(kcost[kti*knumNodes+ktj] - kprice[kti] + kprice[ktj] + kepsilon <= 0){
					kg[kti] -= krb[kti*knumNodes+ktj];
					kg[ktj] += krb[kti*knumNodes+ktj];
					kflow[kti*knumNodes+ktj] = krb[kti*knumNodes+ktj];
				}
		}
		iteratorNum = 0;
		if(threadId == 0)
		{
			kflag = true;
		}
#if FULLDEBUG
		if(threadId == 0){
			printNodes(kg, knumNodes, "g");
		}
		__syncthreads();

		for(int i = lnodes; i < rnodes; i++){
			kg[i] = 0;
		}
		kcheck(
				kg,
				lnodes,
				rnodes
			  );
		__syncthreads();
		if(threadId == 0){
			printf("\nkflag should be true: %d\n", kflag);
			kg[knumNodes/2] = 1;
			printNodes(kg, knumNodes, "g");
		}
		__syncthreads();
		kcheck(
				kg,
				lnodes,
				rnodes
			  );
		__syncthreads();
		if(threadId == 0)
			printf("\nkflag should be false: %d\n", kflag);
		break;
#endif
		__syncthreads();
		kcheck(
			kg,
			lnodes,
			rnodes
		);
		__syncthreads();

		while(!kflag){
			tmpb = 0;
/*			pushFlow(
				lnodes,
				rnodes,
				ledges,
				redges,
				kepsilon,
				knumNodes,
				kflow,
				krb,
				klb,
				kprice,
				kcost,
				kedges,
				kg
				);*/
			if(threadId == 0){
				minRise = MAXMY;
			}
			__syncthreads();
/*			priceRise(
				lnodes,
				rnodes,
				ledges,
				redges,
				kepsilon,
				knumNodes,
				kflow,
				krb,
				klb,
				kprice,
				kcost,
				kedges,
				kg
				);
*/
			__syncthreads();
			if(threadId == 0){
				if(minRise == MAXMY){
					minRise = 0;
				}
			}
			__syncthreads();
			for(int i = lnodes; i < rnodes; i++){
				if(knodesRisePrice[i]){
					kprice[i] += minRise;
				}
			}
			__syncthreads();
			iteratorNum++;
			totalIteratorNum++;
			if(iteratorNum == 5){
				break;
			}

			if(threadId == 0)
			{
				kflag = true;
			}
			kcheck(
				kg,
				lnodes,
				rnodes
			);
			__syncthreads();
		}
		int tans = 0;
		for(int i = ledges; i < redges; i++){
			kti = kedges[i*2 + 0];
			ktj = kedges[i*2 + 1];
			atomicAdd(&tans, kflow[kti*knumNodes + ktj]*kcostRaw[kti*knumNodes + ktj]);
		}
		if(threadId == 0){
			printf("temporary ans: %d\n",tans);
		}
		if(costScale ==0){
			break;
		}
		gdelta = costScale - max(0, costScale - scalingFactor);
		costScale = max(0, costScale - scalingFactor);
	}


	if(threadId == 0)
	{
		printGraph(kcost, knumNodes,"cost");
		printf("kenerl end\n");
	}
	__syncthreads();
}

void run_auction(
		int numNodes,
		int numEdges,
		int threadNum,
		int dC,

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
		dC,
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
		int *dc,
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
	cout << "tnumNodes: "<< tnumNodes << endl;
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
	*dc = tmaxCost;
	cout << "read end\n";
}

int main(int argc, char *argv[]){
	int threadNum = 1024;
	int numNodes = SIZE;
	int numEdges = EDGESIZE;
	int hC;
	int *hedges = new int[EDGESIZE*2];
	int *hcost = new int[SIZE*SIZE];
	int *hg = new int[SIZE];
	int *hlb = new int[SIZE*SIZE];
	int *hrb = new int[SIZE*SIZE];

	int *hflow = new int[SIZE*SIZE];
	memset(hflow, 0, sizeof(hflow));

	initmy(
		&hC,
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
		hC,

		hedges,
		hcost,
		hg,
		hlb,
		hrb,

		hflow
	);
	return 0;
}
