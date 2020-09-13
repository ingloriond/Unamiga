#include <iostream>
#include <cstring>

using namespace std;

int main(int argc, char *argv[]) {
    int sel=1;
    for( int k=1; k<argc; k++ ) {
        if( strcmp(argv[k],"-l")==0 ) { sel=0; continue; }
        cerr << "ERROR: unexpected argument " << argv[k] << '\n';
        cerr << "Use -l to write the lower byte. Otherwise the higher byte is written\n";
        return 1;
    }
    while( !cin.eof() ){
        char c[2];
        cin.read(c,2);
        if(cin.eof()) break;
        cout.write(&c[sel],1);
    };
    return 0;
}