// Converts 16-bit hex file to binary

#include <iostream>
#include <sstream>
#include <string>
#include <iomanip>

using namespace std;

#define BUFSIZE 4096

int main( int argc, char *argv[] ) {
    char *buf=new char[BUFSIZE];
    int k=0;
    while(!cin.eof()) {
        int x;
        string s;
        getline(cin,s);
        stringstream ss(s);
        ss >> hex >> x;
        buf[k++] = (char)(x&0xff);
        buf[k++] = (char)((x>>8)&0xff);
        if(k==BUFSIZE) {
            cout.write( buf,BUFSIZE);
            k=0;
        }
    }
    delete buf;
    return 0;
}