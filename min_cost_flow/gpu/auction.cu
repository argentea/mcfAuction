#include "auction.cuh"
#include "min_cost_flow_gpu.h"

#define MAXMY 0x3f3f3f3f
#define MAXCOST 10000
namespace mcfgpu {
struct PushEdge
{
	int edge;
	int delta;
	int gId; ///< Id of nodes which's grow decrease;
	int nextEdge;
	bool direct;
};
struct PushNode
{
	int nodeId;
	int firstEdgeId;
};



template<class GRA, class NM, class AM, class NI, class AI>
struct AuctionState
{
	struct PushEdge* kpushList;

	int* kpushListFlag;
    bool* knodesRisePrice; ///< length of #nodes 

    void initialize(Graph<GRA, NM, AM, NI, AI> const& G)
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
		cudaMemset(kpushListFlag, 0, G.getNodesNum()*sizeof(int));
        status = cudaMalloc((void **)&knodesRisePrice, G.getNodesNum()*sizeof(bool));
        if (status != cudaSuccess) 
        { 
            printf("cudaMalloc failed for knodesRisePrice\n"); 
        }
        printf("end init\n");
    }

    void destroy()
    {
        cudaFree(knodesRisePrice);
		cudaFree(kpushList);
    }
};

template<class GRA, class NM, class AM, class NI, class AI>
//pushlist is not good
__device__ void pushFlow(
		Graph<GRA, NM, AM, NI, AI> &G,
        AuctionState<GRA, NM, AM,NI, AI>& state, 
		const int lnodes,
		const int rnodes,
        const int node_step, 
		const int ledges,
		const int redges,
        const int edge_step, 
		const int epsilon,
		const int knumNodes, 
		int& kpushCount,
		int& kpushFlag
		){
#if FULLDEBUG
	if(threadIdx.x ==0){
		printf("in pushFlow\n");
	}
	__syncthreads();
#endif
	if(threadIdx.x ==0){
		kpushCount = 0;
	}
	__syncthreads();

	for(int i = ledges; i < redges; i += edge_step){
		int ti,tj,mindex;
        auto const& edge = G.edge(i); 
		ti = edge.source;
		tj = edge.sink;
        int value = G.atCost(i) - G.atPrice(ti) + G.atPrice(tj);
		if(value + epsilon == 0 && G.atGrow(ti) >0){
			mindex = atomicAdd(&kpushCount, 1);
			state.kpushList[mindex].edge = i;
			state.kpushList[mindex].direct = true;
			state.kpushList[mindex].gId = ti;
			state.kpushList[mindex].delta = G.atRb(i) - G.atFlow(i);
		}
		else if (value - epsilon == 0 && G.atGrow(tj) > 0){
			mindex = atomicAdd(&kpushCount, 1);
			state.kpushList[mindex].edge = i;
			state.kpushList[mindex].direct = false;
			state.kpushList[mindex].gId = tj;
			state.kpushList[mindex].delta = G.atFlow(i) - G.atLb(i);
		}
	}
#if (DEBUG && DEBUG1)
	if(threadIdx.x ==0){
		printf("get pushList\n");
		if(kpushCount == 0){
			printf("no edge to push!!\n");
		}
		for(int i = 0; i < kpushCount; i++){
			printf("%d\t", state.kpushList[i].edge);
		}
		printf("\n");
	}
	__syncthreads();
#endif
	__syncthreads();
	int delta,tmpi,tmpj,tmpk;
	/*
	int tdivid = kpushCount / blockDim.x;
	int tmod = kpushCount % blockDim.x;
	int tlb,trb;
	if(threadIdx.x < tmod){
		tlb = threadIdx.x * (tdivid + 1);
		trb = (threadIdx.x + 1) * (tdivid + 1);
	}else{
		tlb = threadIdx.x * tdivid + tmod;
		trb = (threadIdx.x + 1)*tdivid + tmod;
	}
	
	do{
		__syncthreads();
		if(threadIdx.x == 0){
			kpushFlag = 0;
		}
		__syncthreads();
		for(int i = tlb; i < trb; i++){
			tmpk = state.kpushList[i].edge;
			tmpi = state.kpushList[i].gId;
			auto const& edge = G.edge(tmpk);
			if(state.kpushList[i].delta != 0){
				if(atomicAdd(&state.kpushListFlag[tmpi], 1) == 0){
					if(state.kpushList[i].direct){
						tmpj = edge.sink;
						delta = min(G.atGrow(tmpi), state.kpushList[i].delta);
						G.setFlow(tmpk, G.atFlow(tmpk) + delta);
					}else{
						tmpj = edge.source;
						delta = min(G.atGrow(tmpi), state.kpushList[i].delta);
						G.setFlow(tmpk, G.atFlow(tmpk) - delta);
					}
					state.kpushList[i].delta -= delta;
					G.atomicSubGrow(tmpi, delta);
					G.atomicAddGrow(tmpj, delta);
					if(delta != 0){
						atomicAdd(&kpushFlag,1);
					}
				}
				atomicSub(&state.kpushListFlag[tmpi], 1);
			}
		}
		__syncthreads();
	}while(kpushFlag != 0);
*/
	if(threadIdx.x == 0){
		for(int i = 0; i < kpushCount; i++){
			tmpk = state.kpushList[i].edge;
			tmpi = state.kpushList[i].gId;
//				printf("get in: %d\n", tmpi);
			auto const& edge = G.edge(tmpk);
			if(state.kpushList[i].direct){
				tmpj = edge.sink;
				delta = min(G.atGrow(tmpi), state.kpushList[i].delta);
				G.setFlow(tmpk, G.atFlow(tmpk) + delta);
			}else{
				tmpj = edge.source;
				delta = min(G.atGrow(tmpi), state.kpushList[i].delta);
				G.setFlow(tmpk, G.atFlow(tmpk) - delta);
			}
			state.kpushList[i].delta -= delta;
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


template<class GRA, class NM, class AM, class NI, class AI>
__device__ void priceRise(
		Graph<GRA, NM, AM, NI, AI> &G,
        AuctionState<GRA, NM, AM, NI, AI>& state, 
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
#if DEBUG
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
#if DEBUG
					if(tmpb == 0){
						printf("possible\n");
					}
#endif

			if(G.atFlow(i) < G.atRb(i) && state.knodesRisePrice[ti]){
				tmpb = G.atPrice(tj) + G.atCost(i) + epsilon - G.atPrice(ti);
				if(tmpb >= 0){
#if DEBUG
					if(tmpb == 0){
						printf("miRise == 0: node: %d, price: %d, Cost: %d,po\n ",ti, G.atPrice(ti),G.atCost(i));
					}
#endif
					atomicMin(&minRise, tmpb);
				}
			}
			if(G.atFlow(i) > G.atLb(i) && state.knodesRisePrice[tj]){
				tmpa = G.atPrice(ti) - G.atCost(i) + epsilon - G.atPrice(tj);
				if(tmpa >= 0){
#if DEBUG
					if(tmpb == 0){
						printf("miRise == 0: node: %d, price: %d, Cost: %d,po\n ",ti, G.atPrice(ti),G.atCost(i));
					}
#endif
					atomicMin(&minRise, tmpa);
				}
			}
		}
	}
#if DEBUG
		__syncthreads();
		if(threadIdx.x == 0){
			printf("out priceRise\n minRise = %d\n",minRise);
		}
		__syncthreads();
#endif
	__syncthreads();

}

template<class GRA, class NM, class AM, class NI, class AI>
__global__ void __launch_bounds__(1024)
auction_algorithm_kernel(
		Graph<GRA, NM, AM, NI, AI> G, 
        AuctionState<GRA, NM, AM, NI, AI> state,
        int *dTotalCost,
        int *dflow,
        int *dprice
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
	__shared__ int kpushCount;
	__shared__ int kpushFlag;
    __shared__ int tans;

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
					kpushCount,
					kpushFlag
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
#if (DEBUG&&DEBUG1)
			if(threadId == 0){

//				G.printGrow();
				if(minRise == 0)
					printf("iteration : %d  minRise: %d\n", iteratorNum ,minRise);
				int unfeed = 0;
				for(int i = 0; i < G.getNodesNum(); i++){
					if(G.atGrow(i) > 0){
						unfeed += G.atGrow(i);
					}
				}
				printf("unfeed source is %d\n", unfeed);
			}
			__syncthreads();
#endif
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
		tans = 0;
	}
    
	for(int i = ledges; i < redges; i += edge_step){
		atomicAdd(&tans, G.atFlow(i)*G.atCostRaw(i));
	}

	if(threadId == 0){
		printf("inner loop out\n");
		printf("temporary ans: %d\n",tans);
		printf("cost scale: %d\n", costScale);
		printf("iteratorNum: %d\n", iteratorNum);
		printf("totalIteratorNum: %d\n", totalIteratorNum);
		printf("kenerl end\n");

        *dTotalCost = tans;
        for (int i = 0; i < G.getEdgesNum(); ++i) {
            dflow[i] = G.atFlow(i);
        }
        int totalPrice = 0;
        for (int i = 0; i < G.getNodesNum(); ++i) {
            dprice[i] = G.atPrice(i);
            totalPrice += G.atPrice(i);
            //printf("[%d] : %d\n", i, G.atPrice(i));
        }

	}

	__syncthreads();
}


hr_clock_rep timer_start, timer_mem, timer_stop;
template<class G, class NM, class AM, class NI, class AI>
void GPU<G, NM, AM, NI, AI>::run_auction(Graph<G, NM, AM, NI, AI> auctionGraph, int threadNum){
	std::cout << "start run_auction\n";
    ProblemType status = ProblemType::INFEASIBLE;
	cudaProfilerStart();
	std::cout << "start kernel\n";
    
    size_t totalCostSize = sizeof(int);
    size_t flowSize = sizeof(int ) * numEdges;
    size_t priceSize = sizeof(int) * numNodes;

    int *hTotalCost, *dTotalCost;
    hTotalCost = (int *)malloc(totalCostSize);
    cudaMalloc((void **)&dTotalCost, totalCostSize);
    cudaMemcpy(dTotalCost, hTotalCost, totalCostSize, cudaMemcpyHostToDevice);

    int *hflow, *dflow;
    hflow = (int *)malloc(flowSize);
    cudaMalloc((void **)&dflow, flowSize);
    cudaMemcpy(dflow, hflow, flowSize, cudaMemcpyHostToDevice);

    int *hprice, *dprice;
    hprice = (int *)malloc(priceSize);
    cudaMalloc(&dprice, priceSize);
	cudaMemcpy(dprice, hprice, priceSize, cudaMemcpyHostToDevice);


    AuctionState<G, NM, AM, NI, AI> state; 
    state.initialize(auctionGraph);
    auction_algorithm_kernel<<<1,threadNum>>>
		(
		auctionGraph, 
      state, 
      dTotalCost,
       dflow,
      dprice
	);
    status = ProblemType::OPTIMAL;
    state.destroy();
	cudaProfilerStop();
	cudaDeviceSynchronize();
	timer_stop = get_globaltime();
    
    cudaMemcpy(hTotalCost, dTotalCost, totalCostSize, cudaMemcpyDeviceToHost);
    cudaMemcpy(hflow, dflow, flowSize, cudaMemcpyDeviceToHost); 
    cudaMemcpy(hprice, dprice, priceSize, cudaMemcpyDeviceToHost);
    
    memcpy(res.flowMap, hflow, flowSize);
    memcpy(res.potential, hprice, priceSize);
    res.totalCost = *hTotalCost;
    res.pt = status;
    

  /* if (res.totalCost > MAXCOST) {
        printf("totalcost is too big: %d\n", res.totalCost);
        result = ProblemType::UNBOUNDED;
    }
*/
    cudaFree(dTotalCost);
    cudaFree(dflow);
    cudaFree(dprice);
    free(hTotalCost);
    free(hflow);
    free(hprice);

    return ;

}

template<class G, class NM, class AM, class NI, class AI>
void GPU<G, NM, AM, NI, AI>::run(){
	int threadNum = 1024;
//	initmy(&hC,hedges,hcost,hg,hlb,hrb	);
	timer_start = get_globaltime();
	Graph<G, NM, AM, NI, AI> auctionGraph(Graph<G, NM, AM, NI, AI>::edgeList, _map, _supply, _capacity_upper, _cost);
	timer_mem = get_globaltime();
//	Graph auctionGraph = Graph(Graph::matrix,numNodes, numEdges, hC, hedges, hcost, hlb, hrb, hg);

	run_auction(
		auctionGraph,
		threadNum
	);

    std::cout << "run_acution takes "<< (timer_stop - timer_start)*get_timer_period() << "ms totally.\n";
	std::cout << "memory copy takes "<< (timer_mem - timer_start)*get_timer_period() << "ms totally.\n";
	std::cout << "kernel takes "<< (timer_stop - timer_mem)*get_timer_period() << "ms totally.\n";

	std::cerr << "run_acution takes "<< (timer_stop - timer_start)*get_timer_period() << "ms totally.\n";
	std::cerr << "memory copy takes "<< (timer_mem - timer_start)*get_timer_period() << "ms totally.\n";
	std::cerr << "kernel takes "<< (timer_stop - timer_mem)*get_timer_period() << "ms totally.\n";
	return ;
} 

};//end namespace mcfgpu
