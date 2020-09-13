#include <iostream>
#include <iomanip>

using namespace std;

int main() {
    while( true ) {
        unsigned char b[1024];
        cin.read( (char*) b,1024);
        for( int k=0; k<1024; k++ ) {
            unsigned c = b[k];
            c &= 0xff;
            cout << hex << c <<'\n';
        }
        if(cin.eof()) break;
    }
    return 0;
}