#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>

using namespace std;

int main() {
    ifstream fin("video.bin",ios_base::binary);
    if( !fin.good() ) {
        cout << "ERROR: cannot open video.bin\n";
        return 1;
    }
    int srgb;
    bool hsync = false;
    bool vsync = false;
    bool init  = true;

    int rows=0, cols=0;
    int frame=-1;
    ofstream fout;

    bool skip_output = false;

    while( !fin.eof() ) {
        fin.read( (char*) &srgb, 4 );
        if( init ) {
            if( !(srgb&0x2000) ) continue; // wait for first V blank
            init = false;
        }
        if( srgb & 0x2000 ) { // check for VS
            if( !vsync ) {
                if( fout.is_open() ) {
                    cout << frame << " => " << cols << "x" << rows << "\n";
                    fout.close();
                }
                stringstream name;
                frame++;
                name << "video_" << setfill('0') << setw(3) << frame << ".jpg";
                if( ifstream(name.str()).good() ) {
                    skip_output = true;
                }
                else {
                    skip_output = false;
                    name.str("");
                    name << "video_" << setfill('0') << setw(3) << frame << ".raw";
                    fout.open( name.str(), ios_base::binary );
                }
            }
            vsync = true;
            rows=0;
            continue;
        }
        if( srgb & 0x1000 ) { // check for HS
            if( !hsync ) {
                // cout << cols << ", ";
                rows++;
                cols=0;
            }
            hsync = true;
            continue;
        }        
        hsync = false;
        vsync=false;
        int r = (srgb&0xf00)>>8;
        int g = (srgb&0x0f0)>>4;
        int b =  srgb&0x00f;
        r = (r<<4) | r;
        g = (g<<4) | g;
        b = (b<<4) | b;
        // RGB + alpha
        char rgba[4] = { (char)r, (char)g, (char)b, (char)0xff };
        if( !skip_output ) fout.write( rgba, 4 );
        cols++;
    }
    return 0;
}

