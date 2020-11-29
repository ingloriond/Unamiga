#include <iostream>
#include <iomanip>

using namespace std;

const int STEP=1024;

int main() {
    while( true ) {
        unsigned char b[STEP];
        cin.read( (char*) b,STEP);
        for( int k=0; k<cin.gcount(); k++ ) {
            unsigned c = b[k];
            c &= 0xff;
            cout << hex << c <<'\n';
        }
        if(cin.eof()) break;
    }
    return 0;
}