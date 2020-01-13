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

__global__ void __launchbounds__(1024, 4)
auction_algorithm_kernel(
		const int knumNodes,
		const int knumEdges,

		const int* kedges,
		const int* kcost,
		const int* kcostRaw,
		const int* kg,
		const int* kgraw,
		const int* klb,
		const int* krb,
		const int* kprice,
		const int* kflow){
	const int threadId = threadIdx.x;
	int totalIteratorNum = 0;
	int iteratorNum = 0;
	int allIterater = 0;
	int tmpa = 0;
	int tmpb = 0;
	int tmpi = 0;
	scalingFactor = 2;
	int costScale = 9;
	while(costScale >= 0){
		
	}
}

void run_auction(
		int numNodes,
		int numEdges,

		int* hedges,
		int* hcost,
		int* hg,
		int* hlb,
		int* hrb,

		int* hflow){
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
	auction_algorithm_kernel<<<1,EDGESIZE>>>
		(
		numNodes,
		numEdges,
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
	for(int i = 0; i < nodeNum; i++){
		for(int j = 0; j < nodeNum; j++){
			ans += hflow[i*nodeNum + j]*hcost[i*nodeNum + j];
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
		cin >> g[fid-1];
//		cout << a << " " << fid << " " << g[fid-1] << endl;
	}
	int ti,tj;
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
//		cout << a << "\t" << ti << " " << tj << " " << cost[ti][tj] <<" " << lb[ti][tj] << " " << rb[ti][tj] <<  endl;
//		cost[ti][tj] *= nodeNum;
//		cost[ti][tj] %= 4000;
		tmaxCost = max(cost[ti*SIZE + tj], tmaxCost);
		tCapacity = max(rb[ti*SIZE + tj], tCapacity);
	}

int main(int argc, char *argv[]){
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
		*hedges,
		*hcost,
		*hg,
		*hlb,
		*hrb
	);

	run_auction(
		numNodes,
		numEdges,

		hedges,
		hcost,
		hg,
		hlb,
		hrb,

		hflow
	);
	return 0;
}
