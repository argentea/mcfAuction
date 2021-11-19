#include "cpu.h"
#include<iostream>
#include<chrono>
#include<ctime>
#include<fstream>
#include<memory.h>
#include<algorithm>
#include <chrono>
#include <cstdlib>
#include <string>

#include <stdio.h>
#include <stdlib.h>
#include <vector>

#define NUM_THREADS 16
#define SIZE 256
#define EDGESIZE 2048
#define MAXMY 0x3f3f
#define MAXITERATer 10000
using namespace std;
bool GDEBUG = 0;
int costScale = 1;
int scalingFactor = 1;
int gdelta = 0;


namespace mcfcpu {
void CPU::printCost(){
	cout << "*********************\n"
		<< "cost\n"
		<< "********************\n";
	for(int i  = nodeNum-1;i >= 0; i--){
		cout << "i " << i  << " ";
		for(int j = nodeNum-1; j >= 0; j--){
			printf("%d\t", cost[i][j]);
		}
		printf("\n");
	}
}
void CPU::printFolw(){
	cout << "*********************\n"
		<< "flow\n"
		<< "********************\n";
	for(int i  = nodeNum-1;i >= 0; i--){
		for(int j = nodeNum-1; j >= 0 ; j--){
			printf("%d\t", flow[i][j]);
		}
		printf("\n");
	}
}
void CPU::printPi(){
	cout << "*********************\n"
		<< "pi+\n"
		<< "*********************\n";
	for(int i = nodeNum-1; i >= 0; i--){
		for(int j = nodeNum-1; j >= 0; j--){
			printf("%d\t", cost[i][j] - price[i] + price[j]);
		}
		printf("\n");
	}
}

void CPU::printPrice(){
	cout << "*********************\n"
		<< "price\n"
		<< "**********************\n";

	for(int i = 0; i < nodeNum; i++){
		printf("%d\t", price[i]);
	}
	printf("\n");
}
void CPU::printGrow(){
	cout << "*********************\n"
		<< "grow\n"
		<< "********************\n";
	for(int i = 0; i < nodeNum; i++){

		printf("%d\t", g[i]);
	}
	printf("\n");
}
void CPU::printNG(){
	int a = 0;
	for(int i = 0; i < nodeNum; i++){
		if(g[i] > 0){
			a+=g[i];
		}
	}
	cout << "NG ::" << a << endl;
}

int CPU::initmy(){
	cin >> nodeNum >> edgeNum;
	memset(cost, MAXMY, sizeof(cost));
	memset(costRaw, MAXMY, sizeof(costRaw));
	memset(price, 0, sizeof(price));
	memset(graw, 0, sizeof(graw));
	memset(flow, 0, sizeof(flow));
	char a;
	int fid;
	int aNUm;
	cin >> aNUm;
//	cout << "aNUm " << aNUm << endl;
	for(int i = 0; i < aNUm; i++){
		cin >> a >> fid;
		cin >> g[fid-1];
		graw[fid - 1] = g[fid -1];
//		cout << a << " " << fid << " " << g[fid-1] << endl;

	}
	int ti,tj;
	while(true){
		cin >> a >> ti >> tj;
		if(ti == tj && ti==0){
			break;
		}
		ti--;tj--;
		edges[edgeNum][0] = ti;
		edges[edgeNum][1] = tj;
		edgeNum++;
		cin >> lb[ti][tj] >> rb[ti][tj]>>  cost[ti][tj] ;
//		cout << a << "\t" << ti << " " << tj << " " << cost[ti][tj] <<" " << lb[ti][tj] << " " << rb[ti][tj] <<  endl;
//		cost[ti][tj] *= nodeNum;
		costRaw[ti][tj] = cost[ti][tj];
//		cost[ti][tj] %= 4000;
		C = max(cost[ti][tj], C);
		Capacity = max(rb[ti][tj], Capacity);
	}
	int tmp = C;

	while((tmp -= (1 << costScale))>= 0){
		costScale++;
	}
	cout << "*************\n"
		<< "EdgeNum:  " << edgeNum << endl;
	costScale-=4;
	cout << "************\n"
		<< "CostScale    " << costScale << endl
		<< "*************\n";

	return nodeNum;
}

int CPU::pushMy(){
	int pushListPo[SIZE][2];
	int pushListNa[SIZE][2];
	int poCount = 0;
	int naCount = 0;
//#pragma omp parallel for num_threads (NUM_THREADS) reduction(+:poCount) reduction(+:naCount)
	for(int k = 0; k < EDGESIZE; k++){
		int i, j;
		i = edges[k][0];
		j = edges[k][1];
		if(cost[i][j]-price[i]+price[j]+epsilon==0&&g[i]>0){
			pushListPo[poCount][0] = i;
			pushListPo[poCount][1] = j;
			poCount++;
			continue;
		}
		if(cost[i][j]-price[i]+price[j]-epsilon==0&&g[j]>0){
			pushListNa[naCount][0] = j;
			pushListNa[naCount][1] = i;
			naCount++;
			continue;
		}
	}
/*	for(int i = 0; i <  nodeNum; i++){
		for(int j = 0; j < nodeNum; j++){
			if(cost[i][j]-price[i]+price[j]+epsilon==0&&g[i]>0){
				pushListPo[poCount][0] = i;
				pushListPo[poCount][1] = j;
				poCount++;
				continue;
			}
			if(cost[i][j]-price[i]+price[j]-epsilon==0&&g[j]>0){
				pushListNa[naCount][0] = j;
				pushListNa[naCount][1] = i;
				naCount++;
				continue;
			}
		}
	}
*/
	int tmpi,tmpj,delta;

//	cout << "poCount:  " << poCount << "   naCount:  " << naCount << endl;
	for(int i = 0; i < poCount; i++){
		tmpi = pushListPo[i][0];
		tmpj = pushListPo[i][1];
		delta = min(g[tmpi], rb[tmpi][tmpj] - flow[tmpi][tmpj]);
		flow[tmpi][tmpj] += delta;
		g[tmpi] -= delta;
		g[tmpj] += delta;
	}

	for(int i = 0; i < naCount; i++){
		tmpi = pushListNa[i][0];
		tmpj = pushListNa[i][1];
		delta = min(g[tmpi], flow[tmpj][tmpi] - lb[tmpj][tmpi]);
		flow[tmpj][tmpi] -= delta;
		g[tmpi] -= delta;
		g[tmpj] += delta;
	}

	return 0;
}

//一定是从i流向j
int CPU::priceRise(){
	bool nodesRisePrice[SIZE];
	int minRise = 0x7ffff;
	int nodesCount = 0;
	memset(nodesRisePrice, 0, sizeof(nodesRisePrice));
	for(int i = 0; i < nodeNum; i++){
		if(g[i] > 0){
			nodesRisePrice[i] = true;
		}
	}
#pragma omp parallel for num_threads (NUM_THREADS) reduction(min:minRise)
	for(int k = 0; k < EDGESIZE; k++){
		int i, j, swap,tmpa,tmpb;
		i = edges[k][0];
		j = edges[k][1];
		if(nodesRisePrice[i]!=nodesRisePrice[j]){
			if(nodesRisePrice[j]){
				swap = i;
				i = j;
				j = swap;
			}
			if(flow[i][j] < rb[i][j]){
				tmpb =  price[j] + cost[i][j] + epsilon - price[i];
				if(tmpb >= 0){
					if(minRise > tmpb){
						minRise = tmpb;
					}
				}
			}
			if(flow[j][i] > lb[j][i]){
				tmpa = price[j] - cost[j][i] + epsilon - price[i];
				if(tmpa >= 0){
					if(minRise > tmpa){
						minRise = tmpa;
					}
				}
			}
		}
	}
	
	/*
	for(int i = 0; i < nodeNum; i++){
		for(int j = 0; j < nodeNum; j++){
			if(nodesRisePrice[i]&&(!nodesRisePrice[j])){
				if(flow[i][j] < rb[i][j]){
					if(price[j] + cost[i][j] + epsilon - price[i] >= 0){
						minRise = min(price[j] + cost[i][j] + epsilon - price[i], minRise);
					}
				}
				if(flow[j][i] > lb[j][i]){
					if(price[j] - cost[j][i] + epsilon - price[i] >= 0){
						minRise = min(price[j] - cost[j][i] + epsilon - price[i], minRise);
					}
				}
			}
		}
	}
	*/
	if(minRise == 0x7ffff){
		minRise = 0;
	}
	
//	cout << "minRise:  " << minRise << endl;
	for(int i = 0; i < nodeNum; i++){
		if(nodesRisePrice[i]){
			price[i] += minRise;
		}
	}
	return 0;
}

bool CPU::check(){
	bool flag = true;
	for(int i =0; i < nodeNum; i++){
		if(g[i] != 0){
			flag = false;
			break;
		}
	}
	return flag;
}

void CPU::costScalingInit(){
	for(int i = 0; i < nodeNum; i++){
		for(int j = 0; j < nodeNum; j++){
			if(costRaw[i][j] <= C){
				cost[i][j] = costRaw[i][j] / (1 << costScale);
			}
		}
	}
	for(int i = 0; i < nodeNum; i++){
		price[i]*=(1 << gdelta);
	}
	return;
}

void CPU::cycleInit(){
	int maxFlow = 0;
	for(int i = 0; i < nodeNum; i++){
		for(int j =0; j < nodeNum; j++){
			if(cost[i][j] - price[i] + price[j] + epsilon <= 0){
				g[i] -= rb[i][j];
				g[j] += rb[i][j];
				flow[i][j] = rb[i][j];
			}
		}
	}
}

class Graph;

void CPU::run() {
 //   Graph auctionGraph = Graph(Graph::edgeList, fileName);
	typedef chrono::time_point<chrono::system_clock> timePoint;
	timePoint start,mid,end;
	start = chrono::system_clock::now();
	initmy();
	mid = chrono::system_clock::now();
	int totalIteratorNum = 0;
	int iteratorNum = 0;
	int allIterater = 0;
	int tmpa = 0;
	int tmpb = 0;
	int tmpi = 0;
	scalingFactor = 2;
	epsilon = 1;
	for(int i = 0 ; i < SIZE; i++){
		g[i] = graw[i];
	}
	while(!check()){
		tmpb = 0;
		pushMy();
		priceRise();
			for(int i = 0; i < nodeNum; i++){
			if(g[i] > 0){
				tmpb+=g[i];
			}
		}
		if(tmpb != tmpa){
			cout << "iteratorNum:" << tmpa << "  to  "<<tmpb << "  is  " << iteratorNum - tmpi  << "  now iterateNum is  " << iteratorNum<<
					"   epsilon is: " << epsilon << endl;
			tmpi = iteratorNum;
			tmpa = tmpb;
		}

		iteratorNum++;
	}
	int ans = 0;
	for(int i = 0; i < nodeNum; i++){
		for(int j = 0; j < nodeNum; j++){
			ans += flow[i][j]*cost[i][j];
		}
	while(costScale >= 0){
		memset(flow, 0, sizeof(flow));
		for(int i = 0 ; i < SIZE; i++){
			g[i] = graw[i];
		}
		costScalingInit();
		cycleInit();
		cerr << costScale << endl;
		iteratorNum = 0;
//		printGrow();
//		printCost();
		while(!check()){
			tmpb = 0;
			pushMy();
			priceRise();
//			if(iteratorNum - tmpi > 500){
//				cout << "iteratorNum is " << iteratorNum << endl;
//				printPi();
//				printPrice();
//				printGrow();
//			}
/*			for(int i = 0; i < nodeNum; i++){
				if(g[i] >= 0){
					tmpb+=g[i];
				}else if(i==244){
					cout << "nagetive!!!  " << i << endl;
					for(int j = nodeNum-1; j >= 0; j--){
						if( cost[j][i] - price[j] + price[i] < 1000000)
						printf("j: %d %d\t",j,  cost[j][i] - price[j] + price[i]);
					}
					printf("\n");
				}
			}
			if(tmpb != tmpa){
				cout << tmpa << "  to  "<<tmpb << "  is  " << tmpa - tmpb << "   iteratorNum is  " << iteratorNum - tmpi  << "  now iterateNum is  " << iteratorNum<<
					"  cost is: " << costScale << endl;
				tmpi = iteratorNum;
				tmpa = tmpb;		
			}*/
			iteratorNum++;
			totalIteratorNum++;
		}
//		printFolw();
		int ans = 0;
		for(int i = 0; i < nodeNum; i++){
			for(int j = 0; j < nodeNum; j++){
				ans += flow[i][j]*costRaw[i][j];
			}
		}
		cout << "COST SCALING" << costScale;
		cout << "\nNUM:   " << iteratorNum << "  totalNUM:  " << totalIteratorNum<< endl;
		cout << "\n******************\nans: " << ans << "\n******************\n";
		//todo use epsilon factor to reduce epsilon
		if(costScale == 0){
			break;
		}
		gdelta = costScale - max(0, costScale - scalingFactor);
		cout << "gdelta:  " << gdelta << endl;
		costScale = max(0, costScale - scalingFactor);
	}
	end = chrono::system_clock::now();
	chrono::duration<double> initTime = mid - start;
	chrono::duration<double> caculateTime = end - mid;
	cout << "initTime:  " << initTime.count() << "   caculateTime:  " << caculateTime.count() << endl;
	return ;
}

};
