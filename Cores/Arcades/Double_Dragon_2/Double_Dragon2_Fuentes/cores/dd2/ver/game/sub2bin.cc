#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdio>

using namespace std;

int main() {
    ifstream fin("sub.hex");
    int fcnt=0;
    char *buf=new char[1024];
    do {
        for( int b=0; b<1024; b++ ) {
            string s;
            int x;
            getline(fin,s);
            sscanf(s.c_str(),"%x",&x);
            buf[b] = x;
        }
        stringstream fname;
        fname << "sub_" << dec << fcnt << ".bin";
        ofstream fout(fname.str());
        fout.write(buf,1024);
        fcnt++;
    } while( !fin.eof() );

    delete []buf;
}