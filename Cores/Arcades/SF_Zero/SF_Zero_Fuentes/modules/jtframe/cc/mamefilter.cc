#include <iostream>
#include <fstream>
#include <string>

using namespace std;

int main(int argc, char * argv[] ) {
    bool print=false;
    string fname="mame.xml";
    string sysname="gng";
    bool   sysname_assigned=false;
    for( int k=1; k<argc; k++ ) {
        string a = argv[k];
        if( a == "-f" ) {
            if( ++k == argc ) {
                cout << "ERROR: expecting path to mame.xml after -f argument\n";
                return 1;
            }
            fname=argv[k];
            continue;
        }
        if( !sysname_assigned ) {
            sysname = argv[k];
            sysname_assigned = true;
        } else {
            cout << "ERROR: Unknown argument " << argv[k] << "\n";
            return 1;
        }
    }
    string search='\"'+sysname+'\"';
    ifstream fin(fname.c_str());
    if( !fin.good() ) {
        cout << "ERROR: cannot open file " << fname << '\n';
        return 0;
    }

    cout << "<mame>\n";
    while( !fin.eof() ) {        
        string line;
        getline( fin, line );
        if( !print ) {
            if( line.find(search) != string::npos ) print=true;
        }
        if( print ) {
            cout << line << '\n';
            if( line.find("</machine>") != string::npos ) print=false;
        }
    }
    cout << "</mame>\n";
    return 0;
}