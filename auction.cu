#include "auction.cuh"

#define MAXMY 0x3f3f3f3f

struct PushEdge
{
	int edge;
	int delta;
	bool direct;
};

struct AuctionState
{
	struct PushEdge* kpushList;

	int* kpushListDelta;
	int* kpushListFlag;
    bool* knodesRisePrice; ///< length of #nodes 

    void initialize(Graph const& G)
    {
        printf("initialize state with %d nodes\n", G.getNodesNum());
		kpushList = nullptr;
        knodesRisePrice = nullptr; 

		cudaError_t status = cudaMalloc((void **)&kpushList, G.getEdgesNum()*sizeof(PushEdge));
        if (status != cudaSuccess) 
        { 
            printf("cudaMalloc failed for kpushList\n"); 
        } 

		status = cudaMalloc((void **)&kpushListFlag, G.getNodesNum()*sizeof(int));
        if (status != cudaSuccess) 
        { 
            printf("cudaMalloc failed for kpushListFlag\n"); 
        } 
		status = cudaMalloc((void **)&kpushListDelta, G.getEdgesNum()*sizeof(bool));
		if (status != cudaSuccess)
		{
			printf("cudaMalloc failed for kpushListDelta\n");
		}
        status = cudaMalloc((void **)&knodesRisePrice, G.getNodesNum()*sizeof(bool));
        if (status != cudaSuccess) 
        { 
            printf("cudaMalloc failed for knodesRisePrice\n"); 
        } 
    }

    void destroy()
    {
        cudaFree(knodesRisePrice);
		cudaFree(kpushListDelta);
		cudaFree(kpushList);
    }
};

//pushlist is not good
__device__ void pushFlow(
		Graph &G,
        AuctionState& state, 
		const int lnodes,
		const int rnodes,
        const int node_step, 
		const int ledges,
		const int redges,
        const int edge_step, 
		const int epsilon,
		const int knumNodes, 
        int& kpoCount, 
        int& knaCount,
		int& kpushCount
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
		kpushCount = 0;
	}
	__syncthreads();

	for(int i = ledges; i < redges; i += edge_step){
		int ti,tj,tindex,mindex;
        auto const& edge = G.edge(i); 
		ti = edge.source;
		tj = edge.sink;
        int value = G.atCost(i) - G.atPrice(ti) + G.atPrice(tj);
		if(value + epsilon == 0 && G.atGrow(ti) >0){
			tindex = atomicAdd(&kpoCount, 1);
			
			mindex = atomicAdd(&kpushCount, 1);


			state.kpushList[mindex].edge = i;
			state.kpushList[mindex].delta = G.atRb(i) - G.atFlow(i);
			state.kpushList[mindex].direct = true;
			state.kpushListDelta[mindex] = G.atRb(i) - G.atFlow(i);
		}
		else if (value - epsilon == 0 && G.atGrow(tj) > 0){
			tindex = atomicAdd(&knaCount, 1);

			mindex = atomicAdd(&kpushCount, 1);
			state.kpushList[mindex].edge = i;
			state.kpushList[mindex].direct = false;
			state.kpushList[mindex].delta = G.atFlow(i) - G.atLb(i);

			state.kpushListDelta[mindex] = G.atLb(i) - G.atFlow(i);
		}
	}
#if FULLDEBUG
	if(threadIdx.x ==0){
		printf("get pushList\n");
	}
	__syncthreads();
#endif
	__syncthreads();
	int delta,tmpi,tmpj,tmpk;

	int tdivid = kpushCount / blockDim.x;
	int tmod = kpushCount % blockDim.x;
	int tlb,trb,told;
	if(threadIdx.x < tmod){
		tlb = threadIdx.x * (tdivid + 1);
		trb = (threadIdx.x + 1) * (tdivid + 1);
	}else{
		tlb = threadIdx.x * tdivid + tmod;
		trb = (threadIdx.x + 1)*tdivid + tmod;
	}
/*	while(todoCheck){
		for(int i = tlb; i < trb; i++)
		{

		}	
	}
*/
	if(threadIdx.x == 0){
		for(int i = 0; i < kpushCount; i++){
			tmpk = state.kpushList[i].edge;
			auto const& edge = G.edge(tmpk);
			tmpi = edge.source;
			tmpj = edge.sink;
			if(state.kpushList[i].direct){
				delta = min(G.atGrow(tmpi), G.atRb(tmpk) - G.atFlow(tmpk));
			}else{
				delta = -min(G.atGrow(tmpj), G.atFlow(tmpk) - G.atLb(tmpk));
			}
			G.setFlow(tmpk, G.atFlow(tmpk) + delta);
			G.atomicSubGrow(tmpi, delta);
			G.atomicAddGrow(tmpj, delta);
		}
/*
		for(int i = 0; i < kpoCount; i++){
            tmpk = state.kpushListPo[i]; 
            auto const& edge = G.edge(tmpk); 
            tmpi = edge.source; 
            tmpj = edge.sink; 
			delta = min(G.atGrow(tmpi), G.atRb(tmpk) - G.atFlow(tmpk));
			G.setFlow(tmpk, G.atFlow(tmpk) + delta);
			G.atomicSubGrow(tmpi, delta);
			G.atomicAddGrow(tmpj, delta);
		}
		for(int i = 0; i < knaCount; i++){
            tmpk = state.kpushListNa[i]; 
            auto const& edge = G.edge(tmpk); 
            tmpi = edge.sink; 
            tmpj = edge.source; 
			G.setFlow(tmpk, G.atFlow(tmpk) - delta);
			G.atomicSubGrow(tmpi, delta);
			G.atomicAddGrow(tmpj, delta);
		}*/
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
        AuctionState& state, 
		const int lnodes,
		const int rnodes,
        const int node_step, 
		const int ledges,
		const int redges,
        const int edge_step, 
		const int epsilon,
		const int knumNodes, 
        int& minRise
		){
#if FULLDEBUG
		if(threadIdx.x == 0){
			printf("in priceRise\n");
		}
		__syncthreads();
#endif

	int ti,tj,tmpa,tmpb;
	for(int i = lnodes; i < rnodes; i += node_step){
		if(G.atGrow(i) > 0){
			state.knodesRisePrice[i] = true;
		}else {
			state.knodesRisePrice[i] = false;
		}
	}
	__syncthreads();
	for(int i = ledges; i < redges; i += edge_step){
        auto const& edge = G.edge(i);
		ti = edge.source;
		tj = edge.sink;
		if(state.knodesRisePrice[ti] != state.knodesRisePrice[tj]){
			if(G.atFlow(i) < G.atRb(i) && state.knodesRisePrice[ti]){
				tmpb = G.atPrice(tj) + G.atCost(i) + epsilon - G.atPrice(ti);
				if(tmpb >= 0){
					atomicMin(&minRise, tmpb);
				}
			}
			if(G.atFlow(i) > G.atLb(i) && state.knodesRisePrice[tj]){
				tmpa = G.atPrice(ti) - G.atCost(i) + epsilon - G.atPrice(tj);
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
__global__ void __launch_bounds__(1024)
auction_algorithm_kernel(
		Graph G, 
        AuctionState state 
){
	__shared__ int kepsilon;
	__shared__ int totalIteratorNum;
	__shared__ int iteratorNum;
	__shared__ int scalingFactor;
	__shared__ int costScale;
	__shared__ int gdelta;
	__shared__ int knumNodes;
	__shared__ int knumEdges;
	__shared__ int edgesDivThread;
	__shared__ int nodesDivThread;
    __shared__ int kflag; 
    __shared__ int minRise;
    __shared__ int kpoCount;
    __shared__ int knaCount;
	__shared__ int kpushCount;
	__shared__ int kpushFlag;
#if DEBUG
    __shared__ int tans;
#endif

	const int threadId = threadIdx.x;
    if (threadId == 0) {
        kepsilon = 1; 
        totalIteratorNum = 0; 
        iteratorNum = 0; 
        scalingFactor = 2; 
        costScale = 9; 
        gdelta = 0; 
        knumNodes = G.getNodesNum();
        knumEdges = G.getEdgesNum();
        edgesDivThread = max(knumEdges / blockDim.x, 1);
        nodesDivThread = max(knumNodes / blockDim.x, 1);

		printf("in kernel\n");
    }
    __syncthreads();

	//[edgesl,edgesr) is the range of edges that the thread produre
	const int ledges = threadId * edgesDivThread;
	const int redges = min(ledges + edgesDivThread, knumEdges);
    const int edge_step = 1; 

	const int lnodes = threadId * nodesDivThread;
	const int rnodes = min(lnodes + nodesDivThread, knumNodes);
    const int node_step = 1; 

	int kti;
	int ktj;

	while(costScale >= 0){
#if DEBUG
		if(threadId == 0){
			printf("cost scale: %d\n",costScale);
		}
#endif
		for(int i = lnodes; i < rnodes; i += node_step){
			G.setGrow(i , G.atGrowRaw(i));
		}

		int ktmp = 1<<costScale;

		for(int i = ledges; i < redges; i += edge_step){
			G.setFlow(i, 0);
			if(G.atCostRaw(i) <= G.getMaxCost()){
				G.setCost(i, G.atCostRaw(i)/ktmp);
			}
		}
		for(int i = lnodes; i < rnodes; i++){
			G.setPrice(i, G.atPrice(i)*(1 << gdelta));
		}
		__syncthreads();
		for(int i = ledges; i < redges; i += edge_step){
            auto const& edge = G.edge(i);
			kti = edge.source;
			ktj = edge.sink;
			if(G.atCost(i) - G.atPrice(kti) + G.atPrice(ktj) + kepsilon <= 0){
				G.atomicSubGrow(kti, G.atRb(i));
				G.atomicAddGrow(ktj, G.atRb(i));
				G.setFlow(i, G.atRb(i));
			}
		}
		if(threadId == 0)
		{
            iteratorNum = 0;
			kflag = true;
		}
		__syncthreads();

		for(int i = lnodes; i < rnodes; i += node_step){
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
                    state, 
                    lnodes,
                    rnodes,
                    node_step, 
                    ledges,
                    redges,
                    edge_step, 
                    kepsilon,
                    knumNodes, 
                    kpoCount, 
                    knaCount,
					kpushCount
                    );
			if(threadId == 0){
				minRise = MAXMY;
			}
			__syncthreads();
            priceRise(
                    G,
                    state, 
                    lnodes,
                    rnodes,
                    node_step, 
                    ledges,
                    redges,
                    edge_step, 
                    kepsilon,
                    knumNodes, 
                    minRise
                    );
			__syncthreads();
#if DEBUG
			if(threadId == 0){
				if(minRise == 0)
				printf("iteration : %d  minRise: %d\n", iteratorNum ,minRise);
			}
			__syncthreads();
#endif
			if(threadId == 0){
				if(minRise == MAXMY){
					minRise = 0;
				}
			}

			__syncthreads();
			for(int i = lnodes; i < rnodes; i += node_step){
				if(state.knodesRisePrice[i]){
					G.setPrice(i, G.atPrice(i) + minRise);
				}
			}
			__syncthreads();
			if(threadId == 0)
			{
                iteratorNum++;
                totalIteratorNum++;
				kflag = true;
			}
			for(int i = lnodes; i < rnodes; i += node_step){
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
		for(int i = ledges; i < redges; i += edge_step){
			atomicAdd(&tans, G.atFlow(i)*G.atCostRaw(i));
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
        if (threadId == 0) {
            gdelta = costScale - max(0, costScale - scalingFactor);
            costScale = max(0, costScale - scalingFactor);
        }
        __syncthreads();
	}

	if(threadId == 0)
	{
		printf("totalIteratorNum: %d\n", totalIteratorNum);
		printf("kenerl end\n");
	}
}

hr_clock_rep timer_start, timer_mem, timer_stop;
void run_auction(
		Graph auctionGraph,
		int threadNum,
		int* hflow){
	std::cout << "start run_auction\n";

	cudaProfilerStart();
	std::cout << "start kernel\n";
    AuctionState state; 
    state.initialize(auctionGraph);
	auction_algorithm_kernel<<<1,threadNum>>>
		(
		auctionGraph, 
        state
		);
    state.destroy();
	cudaProfilerStop();
	cudaDeviceSynchronize();
	timer_stop = get_globaltime();
}

int main(int argc, char *argv[]){
	int threadNum = 1024;
//	initmy(&hC,hedges,hcost,hg,hlb,hrb	);
	timer_start = get_globaltime();
	Graph auctionGraph = Graph(Graph::edgeList, argv[1]);
	timer_mem = get_globaltime();

//	Graph auctionGraph = Graph(Graph::matrix,numNodes, numEdges, hC, hedges, hcost, hlb, hrb, hg);

    std::vector<int> hflow (auctionGraph.getNodesNum() * auctionGraph.getNodesNum(), 0);
	run_auction(
		auctionGraph,
		threadNum,
		hflow.data()
	);

	std::cerr << "run_acution takes "<< (timer_stop - timer_start)*get_timer_period() << "ms totally.\n";
	std::cerr << "memory copy takes "<< (timer_mem - timer_start)*get_timer_period() << "ms totally.\n";
	std::cerr << "kernel takes "<< (timer_stop - timer_mem)*get_timer_period() << "ms totally.\n";
	return 0;
}
