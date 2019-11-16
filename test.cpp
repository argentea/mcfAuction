#include<iostream>
#include<memory.h>
#include<algorithm>
#define SIZE 512
#define MAXMY 0x3f3f
#define MAXITERATer 10000
using namespace std;
int epsilon;
int nodeNum;
int cost[SIZE][SIZE];
int price[SIZE];
int flow[SIZE][SIZE];
int g[SIZE];
int graw[SIZE];
int lb[SIZE][SIZE];
int rb[SIZE][SIZE];
void printCost(){
	cout << "*********************\n"
		<< "cost\n"
		<< "********************\n";
	for(int i  = nodeNum-1;i >= 0; i--){
		for(int j = nodeNum-1; j >= 0; j--){
			printf("%d\t", cost[i][j]);
		}
		printf("\n");
	}
}
void printFolw(){
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
void printPrice(){
	cout << "*********************\n"
		<< "price\n"
		<< "********************\n";

	for(int i = nodeNum-1; i >=0; i--){
		printf("%d\t", price[i]);
	}
	printf("\n");
}
void printGrow(){
	cout << "*********************\n"
		<< "grow\n"
		<< "********************\n";

	for(int i = nodeNum-1; i >=0; i--){
		printf("%d\t", g[i]);
	}
	printf("\n");
}
void printNG(){
	int a = 0;
	for(int i = 0; i < nodeNum; i++){
		if(g[i] > 0){
			a+=g[i];
		}
	}
	cout << "NG ::" << a << endl;
}

int initmy(){
	cin >> nodeNum;
	memset(cost, MAXMY, sizeof(cost));
	memset(price, 0, sizeof(price));
	memset(graw, 0, sizeof(graw));
	memset(flow, 0, sizeof(flow));
	char a;
	int fid;
	int aNUm;
	cin >> aNUm;
	for(int i = 0; i < aNUm; i++){
		cin >> a >> fid;
		cin >> g[fid-1];
		graw[fid - 1] = g[fid -1];
	}

	int numEdge = 0;
	int ti,tj;
	while(true){
		cin >> a >> ti >> tj;
		if(ti == tj&&ti==0){
			break;
		}
		ti--;tj--;
		cin >> lb[ti][tj] >> rb[ti][tj]>> cost[ti][tj] ;
	}
	return nodeNum;
}

int pushMy(){
	int pushListPo[SIZE][2];
	int pushListNa[SIZE][2];
	int poCount = 0;
	int naCount = 0;
	for(int i = 0; i <  nodeNum; i++){
		for(int j = 0; j < nodeNum; j++){
			if(price[i] == price[j] + cost[i][j] + epsilon){
				pushListPo[poCount][0] = i;
				pushListPo[poCount][1] = j;
				poCount++;
				continue;
			}
			if(price[i] == price[j] - cost[j][i] + epsilon){
				pushListNa[naCount][0] = i;
				pushListNa[naCount][1] = j;
				naCount++;
				continue;
			}
		}
	}

	int tmpi,tmpj,delta;

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


int priceRise(){
	bool nodesRisePrice[SIZE];
	int minRise = 0x7ffff;
	int nodesCount = 0;
	memset(nodesRisePrice, 0, sizeof(nodesRisePrice));
	for(int i = 0; i < nodeNum; i++){
		if(g[i] > 0){
			nodesRisePrice[i] = true;
		}
	}
	
	for(int i = 0; i < nodeNum; i++){
		for(int j = 0; j < nodeNum; j++){
			if(nodesRisePrice[i]&&(!nodesRisePrice[j])){
				if(flow[i][j] < rb[i][j]){
					if(price[j] + cost[i][j] + epsilon - price[i] > 0)
						minRise = min(price[j] + cost[i][j] + epsilon - price[i], minRise);
				}
				if(flow[j][i] > lb[j][i]){
					if(price[j] - cost[j][i] + epsilon - price[i] > 0)
						minRise = min(price[j] - cost[j][i] + epsilon - price[i], minRise);
				}
			}
		}
	}

	for(int i = 0; i < nodeNum; i++){
		if(nodesRisePrice[i]){
			price[i] += minRise;
		}
	}
	return 0;
}

bool check(){
	bool flag = true;
	for(int i =0; i < nodeNum; i++){
		if(g[i] != 0){
			flag = false;
			break;
		}
	}
	return flag;
}


int main(){
	initmy();
	int iteratorNum = 0;
	int allIterater = 0;
	int tmpa = 0;
	int tmpb = 0;
	int tmpi = 0;
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
	}
	cout << "\nNUM\n " << iteratorNum << endl;
	cout << "\n******************\nans: " << ans << "\n******************\n";
	return 0;
}
