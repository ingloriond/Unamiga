#include <iostream>
#include <sstream>
#include <cmath>

using namespace std;

float parse_float(char *s) {
    stringstream ss(s);
    float f;
    ss >> f;
    return f;
}

int main(int argc, char *argv[]) {
    float input_freq=0, target_freq=0;
    for( int k=1; k<argc; k++ ) {
        switch(k) {
            case 1: input_freq  = parse_float(argv[k]); break;
            case 2: target_freq = parse_float(argv[k]); break;
            default:
                cout << "ERROR: unexpected argument. " << argv[k];
                return 1;
        }
    }
    if( input_freq == 0.0 || target_freq == 0.0 ) {
        cout << "Usage: cen_gen input-frequency target-frequency" << endl;
        return 1;
    }
    float best=input_freq;
    int best_n=0, best_d=0;
    for( int n=1; n<1024; n++) {
        for( int d=1; d<1024; d++) {
            float f = (input_freq*n)/d;
            float err = abs(target_freq-f);
            if( err < best ) {
                best_n = n;
                best_d = d;
                best = err;
                cout << n << "/" << d << " = " << f << endl;
            }
        }
    }

}