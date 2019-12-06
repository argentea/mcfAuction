#include<iostream>
#include<memory.h>
#include<algorithm>
#define SIZE 256
#define MAXMY 0x3f3f
#define MAXITERATer 10000
using namespace std;
bool GDEBUG = 0;
int costScale = 1;


int epsilon = 1;
float epsilon_factor = 0.5;

int C = 0;
int Capacity = 0;

int nodeNum;
int edgeNum;
int cost[SIZE][SIZE];
int costRaw[SIZE][SIZE];
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
		cout << "i " << i  << " ";
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
void printPi(){
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
		edgeNum++;
		if(ti == tj&&ti==0){
			break;
		}
		ti--;tj--;
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
	costScale-=4;
	cout << "************\n"
		<< "CostScale    " << costScale
		<< "*************\n";

	return nodeNum;
}

int pushMy(){
	int pushListPo[SIZE][2];
	int pushListNa[SIZE][2];
	int poCount = 0;
	int naCount = 0;
	for(int i = 0; i <  nodeNum; i++){
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

void costScalingInit(){
	for(int i = 0; i < nodeNum; i++){
		for(int j = 0; j < nodeNum; j++){
			if(costRaw[i][j] <= C){
				cost[i][j] = costRaw[i][j] / (1 << costScale);
			}
		}
	}
	for(int i = 0; i < nodeNum; i++){
		price[i]*=2;
	}
	return;
}

void cycleInit(){
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



int main(int argc, char *argv[]){
	if(argc != 1){
		if(argv[1][0] == '1'){
			GDEBUG = true;
		}
	}
	initmy();
	int iteratorNum = 0;
	int allIterater = 0;
	int tmpa = 0;
	int tmpb = 0;
	int tmpi = 0;
	while(costScale >= 0){
		memset(flow, 0, sizeof(flow));
		for(int i = 0 ; i < SIZE; i++){
			g[i] = graw[i];
		}
		costScalingInit();
		cycleInit();
		iteratorNum = 0;
		printGrow();
		printCost();
		while(!check()){
			tmpb = 0;
			pushMy();
			priceRise();
			if(iteratorNum - tmpi > 500){
//				cout << "iteratorNum is " << iteratorNum << endl;
//				printPi();
//				printPrice();
//				printGrow();
			}
			for(int i = 0; i < nodeNum; i++){
				if(g[i] >= 0){
					tmpb+=g[i];
				}/*else if(i==254){
					cout << "nagetive!!!  " << i << endl;
					for(int j = nodeNum-1; j >= 0; j--){
						if( cost[j][i] - price[j] + price[i] < 1000000)
						printf("j: %d %d\t",j,  cost[j][i] - price[j] + price[i]);
					}
					printf("\n");
				}*/
			}
			if(tmpb != tmpa){
				cout << tmpa << "  to  "<<tmpb << "  is  " << tmpa - tmpb << "   iteratorNum is  " << iteratorNum - tmpi  << "  now iterateNum is  " << iteratorNum<<
					"  cost is: " << costScale << endl;
				tmpi = iteratorNum;
				tmpa = tmpb;		
			}
			iteratorNum++;
		}
//		printFolw();
		int ans = 0;
		for(int i = 0; i < nodeNum; i++){
			for(int j = 0; j < nodeNum; j++){
				ans += flow[i][j]*cost[i][j];
			}
		}
		cout << "COST SCALING" << costScale;
		cout << "\nNUM\n " << iteratorNum << endl;
		cout << "\n******************\nans: " << ans << "\n******************\n";
		//todo use epsilon factor to reduce epsilon
		costScale--;
	}
	return 0;
}
