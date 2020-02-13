#include "auction.cuh"

#define MAXMY 0x3f3f3f3f

__device__ int kflag;
#if DEBUG
__device__ int tans;
#endif
__device__ int minRise;
__device__ int kpoCount;
__device__ int knaCount;
__device__ int kpushListPo[SIZE][2];
__device__ int kpushListNa[SIZE][2];
__device__ bool knodesRisePrice[SIZE];
//pushlist is not good
__device__ void pushFlow(
		Graph &G,
		const int lnodes,
		const int rnodes,
		const int ledges,
		const int redges,
		const int epsilon,
		const int knumNodes
		){
#if FULLDEBUG
	if(threadIdx.x ==0){
		printf("in pushFlow\n");
	}
	__syncthreads();
#endif
	if(threadIdx.x ==0){
		kpoCount = 0;
		knaCount = 0;
	}
	__syncthreads();

	for(int i = ledges; i < redges; i++){
		int ti,tj,tindex;
		ti = G.edge2source(i);
		tj = G.edge2sink(i);
		if(G.atCost(ti,tj) - G.atPrice(ti) + G.atPrice(tj) + epsilon == 0&&G.atGrow(ti) >0){
			tindex = atomicAdd(&kpoCount, 1);
			kpushListPo[tindex][0] = ti;
			kpushListPo[tindex][1] = tj;
			continue;
		}
		if(G.atCost(ti,tj) - G.atPrice(ti) + G.atPrice(tj) - epsilon == 0&&G.atGrow(tj) > 0){
			tindex = atomicAdd(&knaCount, 1);
			kpushListNa[tindex][0] = tj;
			kpushListNa[tindex][1] = ti;
			continue;
		}
	}
#if FULLDEBUG
	if(threadIdx.x ==0){
		printf("get pushList\n");
	}
	__syncthreads();
#endif
	__syncthreads();
	int delta,tmpi,tmpj;
	if(threadIdx.x == 0){
		for(int i = 0; i < kpoCount; i++){
			tmpi = kpushListPo[i][0];
			tmpj = kpushListPo[i][1];
			delta = min(G.atGrow(tmpi), G.atRb(tmpi,tmpj) - G.atFlow(tmpi, tmpj));
			G.setFlow(tmpi, tmpj, G.atFlow(tmpi, tmpj) + delta);
			G.atomicSubGrow(tmpi, delta);
			G.atomicAddGrow(tmpj, delta);
		}
		for(int i = 0; i < knaCount; i++){
			tmpi = kpushListNa[i][0];
			tmpj = kpushListNa[i][1];
			delta = min(G.atGrow(tmpi), G.atFlow(tmpj, tmpi) - G.atLb(tmpj,tmpi));
			G.setFlow(tmpj, tmpi, G.atFlow(tmpj, tmpi) - delta);
			G.atomicSubGrow(tmpi, delta);
			G.atomicAddGrow(tmpj, delta);
		}
	}
	__syncthreads();
#if FULLDEBUG
		if(threadIdx.x == 0){
			printf("out pushFlow\n");
		}
		__syncthreads();
#endif

	return ;
}
__device__ void priceRise(
		Graph &G,
		const int lnodes,
		const int rnodes,
		const int ledges,
		const int redges,
		const int epsilon,
		const int knumNodes
		){
#if FULLDEBUG
		if(threadIdx.x == 0){
			printf("in priceRise\n");
		}
		__syncthreads();
#endif

	int ti,tj,tmpa,tmpb;
	for(int i = lnodes; i < rnodes; i++){
		if(G.atGrow(i) > 0){
			knodesRisePrice[i] = true;
		}else {
			knodesRisePrice[i] = false;
		}
	}
	__syncthreads();
	for(int i = ledges; i < redges; i++){
		ti = G.edge2source(i);
		tj = G.edge2sink(i);
		if(knodesRisePrice[ti]!=knodesRisePrice[tj]){
			if(G.atFlow(ti,tj) < G.atRb(ti,tj)&&knodesRisePrice[ti]){
				tmpb = G.atPrice(tj) + G.atCost(ti, tj) + epsilon - G.atPrice(ti);
				if(tmpb >= 0){
					atomicMin(&minRise, tmpb);
				}
			}
			if(G.atFlow(ti,tj) > G.atLb(ti,tj)&&knodesRisePrice[tj]){
				tmpa = G.atPrice(ti) - G.atCost(ti, tj) + epsilon - G.atPrice(tj);
				if(tmpa >= 0){
					atomicMin(&minRise, tmpa);
				}
			}
		}
	}
#if FULLDEBUG
		if(threadIdx.x == 0){
			printf("out priceRise\n");
		}
		__syncthreads();
#endif
	__syncthreads();

}
__global__ void __launch_bounds__(1024, 1)
auction_algorithm_kernel(
		Graph G,
		const int kthreadNum
){
	const int threadId = threadIdx.x;

	
	if(threadId == 0){
		printf("in kernel\n");
	}
	__syncthreads();

	int knumNodes = G.getNodesNum();
	int knumEdges = G.getEdgesNum();

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

	while(costScale >= 0){
#if DEBUG
		if(threadId == 0){
			printf("cost scale: %d\n",costScale);
		}
#endif
		for(int i = lnodes; i < rnodes; i++){
			G.setGrow(i , G.atGrowRaw(i));
		}

		int ktmp = 1<<costScale;

		for(int i = ledges; i < redges; i++){
			kti = G.edge2source(i);
			ktj = G.edge2sink(i);
			G.setFlow(kti, ktj, 0);
			if(G.atCostRaw(kti,ktj) <= G.getMaxCost()){
				G.setCost(kti, ktj, G.atCostRaw(kti,ktj)/ktmp);
			}
		}
		for(int i = lnodes; i < rnodes; i++){
			G.setPrice(i, G.atPrice(i)*(1 << gdelta));
		}
		__syncthreads();
		for(int i = ledges; i < redges; i++){
			kti = G.edge2source(i);
			ktj = G.edge2sink(i);
			if(G.atCost(kti, ktj) - G.atPrice(kti) + G.atPrice(ktj) + kepsilon <= 0){
				G.atomicSubGrow(kti, G.atRb(kti,ktj));
				G.atomicAddGrow(ktj, G.atRb(kti,ktj));
				G.setFlow(kti, ktj, G.atRb(kti,ktj));
			}
		}
		iteratorNum = 0;
		if(threadId == 0)
		{
			kflag = true;
		}
		__syncthreads();

		for(int i = lnodes; i < rnodes; i++){
			if(G.atGrow(i) != 0){
				atomicAnd(&kflag, 0);
			}
		}
		__syncthreads();

		while(!kflag){
#if FULLDEBUG
			if(threadId == 0){
				printf("iteration : %d\n", iteratorNum);
			}
			__syncthreads();
#endif
			pushFlow(
					G,
				lnodes,
				rnodes,
				ledges,
				redges,
				kepsilon,
				knumNodes
				);
			if(threadId == 0){
				minRise = MAXMY;
			}
			__syncthreads();
			priceRise(
					G,
				lnodes,
				rnodes,
				ledges,
				redges,
				kepsilon,
				knumNodes
				);
			__syncthreads();
#if FULLDEBUG
			if(threadId == 0){
				printf("minRise: %d\n", minRise);
			}
			__syncthreads();
#endif
			if(threadId == 0){
				if(minRise == MAXMY){
					minRise = 0;
				}
			}

			__syncthreads();
			for(int i = lnodes; i < rnodes; i++){
				if(knodesRisePrice[i]){
					G.setPrice(i, G.atPrice(i) + minRise);
				}
			}
			__syncthreads();
			iteratorNum++;
			totalIteratorNum++;
			if(threadId == 0)
			{
				kflag = true;
			}
			for(int i = lnodes; i < rnodes; i++){
				if(G.atGrow(i) != 0){
					atomicAnd(&kflag, 0);
				}
			}
			__syncthreads();

		}

#if DEBUG
		if(threadId == 0){
			tans = 0;
		}
		__syncthreads();
		for(int i = ledges; i < redges; i++){
			kti = G.edge2source(i);
			ktj = G.edge2sink(i);
			atomicAdd(&tans, G.atFlow(kti,ktj)*G.atCostRaw(kti,ktj));
		}
		if(threadId == 0){
			printf("inner loop out\n");
			printf("temporary ans: %d\n",tans);
			printf("cost scale: %d\n", costScale);
			printf("iteratorNum: %d\n", iteratorNum);
		}
		__syncthreads();
#endif
		if(costScale ==0){
			break;
		}
		gdelta = costScale - max(0, costScale - scalingFactor);
		costScale = max(0, costScale - scalingFactor);
	}


	if(threadId == 0)
	{
		printf("totalIteratorNum: %d\n", totalIteratorNum);
		printf("kenerl end\n");
	}
	__syncthreads();
}
hr_clock_rep timer_start, timer_mem, timer_stop;

void run_auction(
		Graph auctionGraph,
		int threadNum,
		int* hflow){
	std::cout << "start run_auction\n";
	timer_start = get_globaltime();

	timer_mem = get_globaltime();
	cudaProfilerStart();
	std::cout << "start kernel\n";
	auction_algorithm_kernel<<<1,threadNum>>>
		(
		auctionGraph,
		threadNum
		);
	cudaProfilerStop();
	cudaDeviceSynchronize();
	timer_stop = get_globaltime();
}

int main(int argc, char *argv[]){
	int threadNum = 1024;
	int *hflow = new int[SIZE*SIZE];
	memset(hflow, 0, sizeof(hflow));

//	initmy(&hC,hedges,hcost,hg,hlb,hrb	);
	Graph auctionGraph = Graph(Graph::fakeEdgeList, "../data/data1.min");

//	Graph auctionGraph = Graph(Graph::matrix,numNodes, numEdges, hC, hedges, hcost, hlb, hrb, hg);

	run_auction(
		auctionGraph,
		threadNum,
		hflow
	);

	std::cerr << "run_acution takes "<< (timer_stop - timer_start)*get_timer_period() << "ms totally.\n";
	std::cerr << "memory copy takes "<< (timer_mem - timer_start)*get_timer_period() << "ms totally.\n";
	std::cerr << "kernel takes "<< (timer_stop - timer_mem)*get_timer_period() << "ms totally.\n";
	return 0;
}
