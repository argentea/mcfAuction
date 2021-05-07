#include<iostream>
#include<fstream>
#include<string.h>
using namespace std;
int main(int argc, char* argv[]){
	if(argc <= 1)
	{
		cout << "need file name\n";
		return 0;
	}
	const char* filename = argv[1];
	cerr << "file name: " << filename << endl;
	char tmpfilename[40];
	int length = strlen(filename);
	memcpy(tmpfilename, filename, length);

	tmpfilename[length-3] = 'm';
	tmpfilename[length-2] = 'i';
	tmpfilename[length-1] = 'n';
	cerr << "writen in " << tmpfilename << endl;

	std::ifstream inputfile(filename, std::ios_base::in);
	std::ofstream tmpfile("tmpfile", std::ios_base::out);
	int namelength = strlen(filename);
	std::ofstream outputfile("testdata1",std::ios::out);
	char tmp[20];
	inputfile >> tmp;
	if(strcmp(tmp, "@nodes") == 0){
		cerr << "good!\n";
	}
	inputfile >> tmp >> tmp >> tmp >> tmp;
	cerr << tmp << endl;
	int nodesNo;
	int aNum = 0;
	int nodesCount = 0;
	int supply;
	inputfile >> tmp;
	cerr << tmp << endl;
	while(strcmp(tmp,"@arcs")!=0){
		nodesCount++;
		nodesNo = atoi(tmp);
		inputfile >> supply >> tmp >> tmp >> tmp;
		if(supply != 0){
			tmpfile << "n " << nodesNo+1 << " " << supply << endl;
			aNum++;
		}
	}
	cerr << "nodes end" << endl;
	int edgeNo;
	int source;
	int sink;
	int edgeCount = 0;
	int capacity;
	int cost;
	int tmpint;
	inputfile >> tmp >> tmp >> tmp >> tmp;
	inputfile >> source;
	cerr << tmp << " " << source << endl;
	while(!inputfile.eof()){
		inputfile  >> sink >> edgeNo >> capacity >> cost >> tmpint;
		tmpfile << "a " << source+1<< " " << sink+1 << " " << 0 << " " << capacity << " " << cost  <<  endl;
		inputfile >> source;
		edgeCount++;
	}
	cerr << nodesCount << endl;
	cerr << nodesCount << endl;
	cerr << edgeCount  << endl;
	outputfile << nodesCount << endl << edgeCount << endl << aNum << endl;
	tmpfile.close();
	std::ifstream tmpfile1( "tmpfile", std::ios_base::in); 
	outputfile << tmpfile1.rdbuf();

	
	return 0;
}
