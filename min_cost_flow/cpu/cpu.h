/*************************************************************************
	> File Name: cpu.h
	> Author: zhouyuan
	> Mail: 3294207721@qq.com 
	> Created Time: Mon Apr 19 11:09:48 2021
 ************************************************************************/

#ifndef _CPU_H
#define _CPU_H
#include<iostream>
#include<chrono>
#include<ctime>
#include<memory.h>
#include<algorithm>
#include <lemon/smart_graph.h>
#define NUM_THREADS 16
#define SIZE 256
#define EDGESIZE 2048
#define MAXMY 0x3f3f
#define MAXITERATer 10000
using namespace std;
using namespace lemon;
namespace mcfcpu {



class CPU{
public:
    CPU(const SmartDigraph &g, bool GDEBUG = 0, 
            int costScale = 1,
            int scalingFactor = 1,
            int gdelta = 0,
            int epsilon = 1,
            float epsilon_factor = 0.5,
            int C = 0,
            int Capacity = 0,
            int nodeNum = 0,
            int edgeNum = 0):
        _g(g),
        GDEBUG(GDEBUG),
        costScale(costScale),
        scalingFactor(scalingFactor),
        gdelta(gdelta),
        epsilon(epsilon),
        epsilon_factor(epsilon_factor),
        C(C),
        Capacity(Capacity),
        nodeNum(nodeNum),
        edgeNum(edgeNum){}
        void run();
    ~CPU() {}
private:
    void printCost();
    void printFolw();
    void printPi();
    void printPrice();
    void printGrow();
    void printNG();
    int initmy();
    int pushMy();
    int priceRise();
    bool check();
    void costScalingInit();
    void cycleInit();
    
    const SmartDigraph& _g;
    bool GDEBUG = 0;
    int costScale = 1;
    int scalingFactor = 1;
    int gdelta = 0;

    int epsilon = 1;
    float epsilon_factor = 0.5;

    int C = 0;
    int Capacity = 0;

    int nodeNum;
    int edgeNum;
    int edges[EDGESIZE][2];
    int cost[SIZE][SIZE];
    int costRaw[SIZE][SIZE];
    int price[SIZE];
    int flow[SIZE][SIZE];
    int g[SIZE];
    int graw[SIZE];
    int lb[SIZE][SIZE];
    int rb[SIZE][SIZE];
};

};
#endif
