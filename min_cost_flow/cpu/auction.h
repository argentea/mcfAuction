/*************************************************************************
	> File Name: auction.h
	> Author: zhouyuan
	> Mail: 3294207721@qq.com 
	> Created Time: Mon Apr 26 02:57:18 2021
 ************************************************************************/

#ifndef _AUCTION_H
#define _AUCTION_H



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
		Graph(graphType htype, std::shared_ptr<GraphImpl> gra){
			type = htype;
			int sizeNodeArray = 0;
			int sizeEdgeArray = 0;
            
            numNodes = countNodes(gra->g());
            numNodes = countArcs(gra->g());
            
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
            
            
            for (SmartDigraph::NodeIt n(gra->g()); n != INVALID; ++n) {
                int cnt = gra->nodeLabel()[n];
                hgrow[cnt] = gra->supply()[n];
            }

            for (SmartDigraph::ArcIt arc(gra->g()); arc != INVALID; ++arc) {
                int cnt = gra->arcLabel()[arc];
                //int cnt = g.id(a);
                int sta = gra->nodeLabel()[gra->g().source(arc)];
                int end = gra->nodeLabel()[gra->g().target(arc)];
                hedges[cnt].source = sta;
                hedges[cnt].sink = end;
                if (type == edgeList) {
                    hlb[cnt] = 0;
                    hrb[cnt] = gra->cap()[arc];
                    hcost[cnt] = gra->cost()[arc];
				    maxCost = max(hcost[cnt],maxCost);
				    maxCapacity = max(hrb[cnt], maxCapacity);
                }

                if (type == matrix){
				    hlb[sta * numNodes + end] = 0;
                    hrb[sta * numNodes + end]  = gra->cap()[arc];
                    hcost[sta * numNodes + end] = gra->cost()[arc];
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

#endif
