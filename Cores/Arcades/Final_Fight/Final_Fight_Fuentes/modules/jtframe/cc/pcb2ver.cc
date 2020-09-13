#include <string>
#include <map>
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cstring>
#include <iomanip>
#include <sstream>
#include <list>
#include <set>

using namespace std;
typedef map<int,string> Pins;
typedef map<string,string> Parameters;

class Component{
        Pins pins;
        string instance, type;
        Component *alt_names;
        Parameters params;
    public:
        Component( string _inst, string _type ) : instance(_inst), type(_type) {
            //cout << "Component " << instance << " of type " << type << '\n';
            alt_names=NULL;
        }
        const string& get_name() { return instance; }
        const string& get_type() { return type; }
        const Pins& get_pins() { return pins; }
        int pin_count() { return pins.size(); }
        void set_pin(int k, const string& val);
        void set_ref( Component *alt ) { 
            if( alt == NULL ) {
                cout << "ERROR: No pair for type " << type << "\n";
                return;
            }
            // cout << instance << " paired with " << alt->get_name() << '\n';
            alt_names=alt; 
        }
        string get_alt_name( int k); // Get alternative name for pin k from reference
        string get_pinname(int k);
        void add_parameter( const string& name, const string& value ) {
            params[name] = value;
        }
        friend void dump(Component& c);
};

string Component::get_alt_name( int k ) {
    if( alt_names )
        return alt_names->get_pinname(k);
    else
        return "Unknown_pin";
}

string Component::get_pinname(int k) {
    auto i = pins.find(k);
    if( i != pins.end() ) return i->second;
    else return "Unknown_pin";
}

void Component::set_pin(int k, const string& val ) {
    pins[k]=val;
}

typedef map<string,Component*> ComponentMap;

void delete_map( ComponentMap& m ) {
    while( m.size() ) {
        delete m.begin()->second;
        m.erase( m.begin() );
    }
}

typedef list<class Element*> Elements;

class Element {
    string name;
    Elements values;
    Element *parent;
    string scalar;
public:
    Element( const string _name, Element *_parent ) : name(_name), parent(_parent) {
    }
    const Element* find_child( const string& ref ) const;
    void add_child(Element *c) { values.push_back(c); }
    void set_scalar( const string& s) { scalar=s; }
    const string& get_scalar() const { return scalar; }
    void dump(int indent=0);
    const Elements& get_elements() const { return values; }
    const string& operator[](const string&);
    const string& get_name() const { return name; }
    virtual ~Element();
};

Element::~Element() {
    for( auto& k : values ) {
        delete k;
        k = NULL;
    }
    values.clear();
}

void Element::dump( int indent ) {
    for(int k=indent; k--; ) cout << ' ';
    cout << name << "*" << scalar << "\n";
    for( auto k:values ) {
        k->dump(indent+2);
    }
}

const string& Element::operator[](const string& ref) {
    for( auto k : values ) {
        if( k->name == ref ) return k->scalar;
    }
    cout << "Error: Element " << ref << " not found\n";
    throw 5;
}

void flatten( ifstream& f, string& s ) {
    f.seekg(0, ios_base::end);
    int len = f.tellg();
    f.seekg(0, ios_base::beg);
    char *all = new char[len+1];
    int k=0;
    bool blank=false;
    while(k<len && !f.eof()) {
        char c;
        f.get(c);
        if( c==' ' || c=='\t' || c=='\n' ) {
            if(!blank) all[k++]=' ';
            blank = true;
        } else {
            all[k++]=c;
            blank = false;
        }
    }
    all[k]=0;
    s = all;
    delete all;
}

ifstream open_file(const string& name ) {
    ifstream f(name);
    if( !f.good() ) {
        cout << "Error: cannot open file " << name << '\n';
        throw 1;
    }
    return f;
}

int parse_netlist( const char* s, int k, int len, Element *parent );
void parse_library( const char *fname, ComponentMap& comps );
int match_parts( ComponentMap& comps, ComponentMap& mods );
void dump_wires( ComponentMap& comps, set<string>& ports );
void dump(Component& c);

const Element* Element::find_child( const string& ref ) const {
    if( name == ref ) {
        return this;
    } else {
        for( auto k : values ) {
            const Element *e = k->find_child(ref);
            if( e!=NULL ) return e;
        }
    }
    return NULL;
}

void make_comp_map( const Element *root, ComponentMap& comps ) {
    const Element* e = root->find_child("components");
    if( e == NULL ) return;
    for( auto k: e->get_elements() ) {
        if( k->get_name() == "comp" ) {
            const string& ref = (*k)["ref"];
            Component *new_component = new Component( ref, (*k)["value"] );
            comps[ ref ] = new_component;
            // cout << ref << "->" << (*k)["value"]  << '\n';
            const Element *fields = k->find_child("fields");
            if( fields != NULL ) {
                for( auto f : fields->get_elements() ) {
                    if( f->get_name()!="field" ) continue;
                    string field_name = (*f)["name"];
                    new_component->add_parameter( field_name, f->get_scalar() );
                }
            }
        }
    }
    // now fill nets
    e = root->find_child("nets");
    if( e==NULL ) return;
    for( auto k : e->get_elements() ) {
        if( k->get_name()=="net" ) {
            string net_name = (*k)["name"];
            
            if( net_name.size()>4 && net_name.substr( net_name.size()-4)=="/VDD" ) {
                net_name="1'b1";
            }
            if( net_name.size()>4 && net_name.substr( net_name.size()-4)=="/VSS" ) {
                net_name="1'b0";
            }
            for( int c=0; c<net_name.size(); c++ ) {
                const char cc = net_name[c];
                if(cc=='/' || cc=='(' || cc==')' || cc=='-') net_name[c]='_';
            }
            for( auto refs : k->get_elements() ) {
                if( refs->get_name()!="node" ) continue;
                string ref = (*refs)["ref"];
                string pin_str = (*refs)["pin"];
                int pin = atoi(pin_str.c_str());
                comps[ref]->set_pin( pin, net_name );
            }
        }
    }
}

void flatten_verilog( ifstream&f, string& flat ) {
    f.seekg(0, ios_base::end);
    int len = f.tellg();
    f.seekg(0, ios_base::beg);
    flat.clear();
    flat.reserve(len);
    int last=0;
    while( !f.eof() ) {
        char c,d;
        f.get(c);
        if( c=='/' ) {
            f.get(d);
            if( d=='/' ) {
                // ignore rest of the line
                do{ f.get(c); } while( c!='\n' && !f.eof() );
            }
            if( d=='*' ) {
                // ignore until end of comment
                bool end=false;
                while( !f.eof() ) {
                    f.get(c);
                    if( c=='*' ) {
                        f.get(c);
                        if(c=='/') { f.get(c); break; }
                    }
                }
            }
        }
        if( c=='\t' ) c=' ';    // no tabs
        if( !(last==' ' && c==' ') ) flat.push_back(c); // no more than one space
        last=c;
    }
}

void parse_ports( const string& ports_name, set<string>& ports ) {
    ifstream f(ports_name);
    string flat;
    flatten_verilog( f, flat );
    stringstream ss(flat);
    //cout << flat;    
    while( !ss.eof() ) {
        string line;
        getline( ss, line );
        // cout << line << '\n';
        size_t p = line.find("input");
        if( p==string::npos ) p = line.find("output");
        if( p==string::npos ) p = line.find("inout");
        if( p!=string::npos ) {
            // cout << '*';
            p = line.find_first_of(' ',p)+1;
            size_t p2 = line.find_first_of(" ,;\n",p);
            if( p2 == string::npos ) {
                //cout << "ERROR: Syntax error in port verilog file\n";
                //cout << '\t' << line << '\n';
                //cout << line.substr(p) << '\n';
                //throw 6;
                p2 = line.size();
            }
            string new_port = line.substr(p,p2-p);
            if( new_port[0]=='[' ) {
                p2 = line.find_first_of(']');
                if( p2==string::npos ) {
                    cout << "ERROR: Syntax error in port verilog file. Expecting ']'\n";
                    cout << '\t' << line << '\n';
                    throw 6;
                }
                p=p2+2;
                p2 = line.find_first_of(" ,;\n",p);
                new_port = line.substr(p,p2-p);
            }
            ports.insert(new_port);
        }
    }
//    for( auto k : ports ) cout << k << '\n';
}

int main(int argc, char *argv[]) {
    string fname, libname="../hdl/jt74.v", ports_name;
    bool do_wires=false;
    bool parselib_only=false;
    // parse command line
    for(int k=1; k<argc; k++ ) {
        if( strcmp(argv[k],"--wires")==0 || strcmp(argv[k],"-w")==0 ) {
            do_wires=true;
            continue;
        }
        if( strcmp(argv[k],"--parselib")==0 ) {
            parselib_only=true;
            continue;
        }
        if( strncmp(argv[k],"--lib",5)==0 || strcmp(argv[k],"-l")==0 ) {  
            ++k;          
            if( k >= argc) {
                cout << "ERROR: expecting path to library after -l/--lib argument\n";
                return 1;
            }
            if( argv[k-1][1]=='l' ) {
                if( k == argc ) {
                    cout << "ERROR: expecting path to library file after -l argument.\n";
                    return 1;
                }
                libname = argv[k];
            }
            else {
                libname = string(argv[k]);
            }
            if( !ifstream(libname).good() ) {
                cout << "ERROR: cannot open library file: " << libname << '\n';
                return 1;
            }
            continue;
        }         
        if( strncmp(argv[k],"--ports",5)==0 || strcmp(argv[k],"-p")==0 ) {  
            ++k;          
            if( k >= argc) {
                cout << "ERROR: expecting path to verilog file after " << argv[k-1] << " argument\n";
                return 1;
            }
            ports_name = string(argv[k]);
            if( !ifstream(ports_name).good() ) {
                cout << "ERROR: cannot open verilog file: " << ports_name << '\n';
                return 1;
            }
            continue;
        }  
        if( strcmp(argv[k],"--help")==0 || strcmp(argv[k],"-h")==0 ) {
            cout << "pcb2ver, part of JTFRAME open source hardware development framework.\n";
            cout << "KiCAD netlist to verilog converter.\n";
            cout << "(c) Jose Tejada Gomez (aka jotego) 2019\n";
            cout << "Contact twitter: @topapate\n\n";
            cout << "Usage: pcb2ver netlist-file [--wires|-w] [--lib=|-l path-to-library]\n";
            cout << "\t\t--wires or -w: add wire definition for signals at top of the file.\n";
            cout << "\t\t--lib or -l  : set path to library file.\n";
            cout << "\t\t               The libray file must contain a list of verilog modules,\n";
            cout << "\t\t               after the module name there must be a comment and a ref\n";
            cout << "\t\t               statement. After each port there must be a comment and a\n";
            cout << "\t\t               pin statement. Check out hdl/jt74.v in jtframe for several\n";
            cout << "\t\t               examples.\n";
            cout << "\t\t--parselib   : exit after parsing the lib.\n";
            cout << "\t\t--ports or -p: the ports listed in the verilog file given after --ports\n";
            cout << "\t\t               will be excluded from the wire dump.\n";
            cout << "\tpcb2ver -h|--help\n\t\tDisplays this help message.\n";
            return 0;
        }
        if( argv[k][0]=='-' ) {
            cout << "ERROR: unknown option: " << argv[k];
            cout << "\n\tUse --help to obtain a list of valid options\n";
            return 1;
        }
        if( fname.size()!=0 ) {
            cout << "ERROR: input file was already assigned to " << fname << ".\n";
            return 1;
        }
        fname = argv[k];
        if( !ifstream(fname).good() ) {
            cout << "ERROR: Cannot find file " << fname << '\n';
            return 1;
        }
    }
    if( fname=="" && !parselib_only) {
        cout << "ERROR: must provide a KiCAD netlist file name\n";
        cout << "\tpcb2ver netlist\n";
        return 1;
    }

    Element root("root", NULL);
    ComponentMap comps, mods;
    set<string> ports;
    try{
        parse_library(libname.c_str(), mods);
        if( !parselib_only ) {
            ifstream f = open_file(fname);
            string netlist;
            flatten(f, netlist);
            f.close();
            parse_netlist( netlist.c_str(), 0, netlist.size(), &root );
            make_comp_map( &root, comps );

            if( match_parts( comps, mods ) != 0 ) {
                throw 3;
            };
            if( ports_name.size() ) {
                parse_ports( ports_name, ports );
            }
            if( do_wires ) dump_wires( comps, ports );
            for( auto& k : comps ) {
                dump(*k.second);
            }            
            // root.dump();
        }
    }
    catch( int e ) {
        cout << "Error code " << e << '\n';
        return e;
    }
    return 0;
}

int parse_netlist( const char* s, int k, int len, Element *parent ) {
    Element *new_element = NULL;
    enum {init=0, name=1, body=2} state;
    state = init;

    string new_name;
    while( k<len ) {
        switch( state ) {
            case init: 
                while( s[k]==' ') k++;
                if( s[k]=='(' ) {
                    k++;
                    state = name;
                    continue;
                }
                cout << "Error: syntax error in netlist file\n";
                throw 3;
            case name:
                if( s[k]=='(') {
                    cout << "ERROR: unexpected (\n";
                    throw 2;
                }
                while( s[k]==' ') k++;
                do{
                    new_name.push_back(s[k++]);
                }while( s[k]!=' ' && s[k]!='(' && s[k]!=')' && k<len);
                new_element = new Element( new_name, parent );
                parent->add_child( new_element );
                state=body;
                continue;
            case body: {
                string new_value;
                while( s[k]==' ') ++k;
                if( s[k]==')' ) return k+1;
                if( s[k]=='(') {
                    k = parse_netlist( s, k, len, new_element );
                    continue;
                }
                if( s[k]=='"' ) {
                    while( s[++k] != '"' && k<len) {
                        if( s[k]=='\\' && s[k+1]=='\"' ) {
                            k++;
                        }
                        new_value.push_back(s[k]);
                    }
                    ++k; // skip the "
                }
                else do{new_value.push_back(s[k++]);}while( s[k] != ')' && k<len);
                new_element->set_scalar( new_value );
                continue;
            }
            default:
                cout << "ERROR: parsing problem. state= " << state << "\n";
                throw 3;
        }
    }
    return k;
}

void dump(Component& c) {
    // module instantiation
    cout << c.alt_names->type << " ";
    if( c.params.size()>0 ) {
        cout << "#(";
        bool first = true;
        for( auto k : c.params ) {
            if( !first ) cout << ",\n    ";            
            cout << "." << k.first << "(" << k.second << """) ";
            first = false;
        }
        cout << "\n) ";
    }
    if( c.instance[0]>='0' && c.instance[0]<='9')
        cout << "u_";   // if the instance names starts with a number, add "u_"
    cout << c.instance;
    cout << "(\n";
    int count = c.pin_count();
    typedef map<int,string> BusIndex;
    typedef map<string, BusIndex *> BusMap;
    BusMap buses;
    set<string> ignores;
    // ignore pins with these names
    ignores.insert("VDD");
    ignores.insert("VCC");
    ignores.insert("VSS");
    ignores.insert("GND");    
    bool first=true;
    // first dump all pins which are not buses
    for( auto k : c.pins ) {
        string pin_name = c.get_alt_name(k.first);
        if( ignores.count(k.second)!=0 ) {
            count--;
            continue; // this is power pin
        }
        size_t pos;
        if( (pos=pin_name.find("[")) != string::npos ) {
            // this is part of a bus
            string bus = pin_name.substr(0,pos);
            BusMap::iterator this_bus = buses.find(bus);
            BusIndex* bi=NULL;
            if( this_bus == buses.end() ) { // first element of this bus
                bi = new BusIndex;              
                buses[bus] = bi;
            } else {
                bi = this_bus->second;
            }
            pos++;
            // cout << pin_name << "\n\t";
            int bus_pin = atoi( pin_name.substr(pos).c_str() );
//            cout << "bus pin: " << bus_pin << " -> " << k.second << '\n';
            (*bi)[bus_pin] = k.second;
            continue;
        }
        if( !first ) cout << ",\n";
        cout << "    ." << setiosflags(ios_base::left) << setw(10) << pin_name
             << "( " << setw(24) << k.second << " )";
        cout << " /* pin " << k.first << "*/ ";
        first = false;
        //if( --count ) cout << ',';
        //cout << '\n';
    }
    // Now the buses
    count = buses.size();
    for( auto k : buses ) {
        BusIndex *bi = k.second;
        if( !first ) cout << ",\n";
        cout << setw(0) << "    ." << setiosflags(ios_base::left) << setw(10) << k.first;
        // cout << "// bus: " << k.first << " of size " << bi->size() << '\n';     
        cout << "({ ";
        for( int i= bi->size()-1;  i>=0; i-- ) {
            cout << bi->at(i);
            if(i) cout << ",\n                  "; else cout << "})";
        }
        // if( --count ) cout << ',';
        // cout << '\n';
    }
    cout << "\n);\n\n";    
    // free memory
    for( auto k : buses ) {
        delete k.second;
    }
};

void dump_wires( ComponentMap& comps, set<string>& ports ) {
    set<string> wires;
    // collect buses
    map<string,int> buses;
    for( auto& k : comps ) {
        const Pins& pins = k.second->get_pins();
        for( auto& p : pins ) {
            string full_name = p.second;
            size_t pos = full_name.find('[');
            if( pos != string::npos ) {
                // found a bus!
                string bus_name = full_name.substr(0,pos);
                size_t pos2=full_name.find(']');
                pos++;
                int v = atol( full_name.substr( pos, pos2-pos ).c_str() );  
                auto m = buses.find(bus_name);
                if( m==buses.end() ) {
                    buses[bus_name] = v;
                } else {
                    if( m->second < v ) m->second = v;
                }
            }            
            else wires.insert( p.second ); // regular wire
        }
    }
    // dump the buses
    for( auto& m : buses ) {
        if( ports.count(m.first)==0 ) // skip ports
            cout << "wire [" << m.second << ":0] " << m.first << ";\n";
    }
    // now dump the wires
    for( auto& w : wires ) {
        if( w[0] != '1' && ports.count(w)==0 ) 
            cout << "wire " << w << ";\n";
    }
    // check for unused ports:
    for( auto& p : ports ) {
        int found= buses.count(p) + wires.count(p);
        if(found==0) {
            cerr << "Warning: port " << p << " is not used\n";
        }
    }
}

int match_parts( ComponentMap& comps, ComponentMap& mods ) {
    int unmatched=0;
    for( auto& k : comps ) {
        Component *ref = NULL;
        const string& type = k.second->get_type();
        // cout << "Searching for " << type << '\n';
        for( auto& j : mods ) {
            const string& mod_name = j.second->get_name();
            // cout << "\t" << mod_name << '\n';
            if( type.size() != mod_name.size() ) continue;
            for(int c=0; c<type.size(); c++ ) {
                if( mod_name[c]=='?' ) continue;
                if( mod_name[c]!=type[c] ) goto nope;
            }
            ref = j.second;
            nope:
            continue;
        }
        if( ref==NULL ) unmatched++;
        k.second->set_ref(ref);
    }
    return unmatched;
}

void strip_blanks(string &s ) {
    string b;
    b.reserve( s.size() );
    bool blank=false;
    for( int i=0; i<s.size(); i++ ) {
        if( s[i] == ' ' || s[i] == '\t' ) {
            b.append( 1, ' ' );
            while( i+1<s.size() && (s[i+1]==' ' || s[i+1]=='\t') ) i++;
        }
        else b.append( 1, s[i] );
    }
    // remove the trailing blank
    if( b.size()>0 && b[b.size()-1] == ' ' ) b=b.substr(0,b.size()-1);
    s = b;
}

void parse_library( const char *fname, ComponentMap& comps ) {
    ifstream fin(fname);
    if( !fin.good() ) {
        cout << "ERROR: problem with library file " << fname << '\n';
        cout << "provide a valid library file path via --lib command.\n";
        throw 2;
    }
    while( !fin.eof() ) {
        // find a line with module and ref definitions
        const string mod_tag("module");
        string line;
        getline( fin, line );
        strip_blanks( line );
        size_t pos  = line.find("module");
        size_t pos2 = line.find("// ref:");
        if( pos != string::npos && pos2 != string::npos && pos<pos2 ) {
            pos += 7;
            if( pos > line.size() ) continue;
            size_t aux = line.find_first_of(" )", pos );
            if( aux == string::npos ) continue;
            string module_name = line.substr(pos, aux-pos-1);
            pos2+=7;
            if( line[pos2]==' ' ) pos2++;
            string ref_name = line.substr(pos2);
            Component *p = new Component( ref_name, module_name );
            // cout << "reference " << ref_name << '\n';
            // add ports
            while(!fin.eof()) { // search for all ports
                getline( fin, line );
                strip_blanks( line );
                if( line.find(")")!=string::npos ) break; // end of module
                // is it a bus?
                int bus=-1;
                pos = line.substr(0, line.find("//")).find( "[" );
                if( pos != string::npos ) {
                    pos++;
                    pos2 = line.find(":",pos);
                    string bus_def = line.substr(pos, pos2-pos);
                    // cout << "bus def=" << bus_def << endl;
                    bus = atoi( bus_def.c_str() );
                    // cout << "Found bus of size " << bus << ":0\n";
                }
                pos = line.find( "// pin:" );
                if( pos!=string::npos ) { // found pin!
                    // find pin name
                    string name = line.substr(0,pos);
                    pos = name.find_last_of(",");
                    if( pos == string::npos ) {
                        pos = name.find_last_of(" ");
                        if( pos == string::npos ) {
                            cout << "Warning: // pin: statement found on an incomplete line.\n";
                            cout << line << '\n';
                            continue;   // this port will be ignored
                        }
                    }
                    name = name.substr(0,pos); // remove comma
                    pos2 = name.find_last_of(" ");
                    if( pos2 == string::npos ) {
                        cout << "Warning: // pin: statement found on an incomplete line.\n";
                        cout << line << '\n';
                        continue;
                    }
                    name = name.substr(pos2+1);
                    string pin_str = line.substr( line.find("// pin:")+7 );
                    pos=0;
                    do{
                        string pin_alpha;
                        size_t pin_next = pin_str.find(",",pos);                        
                        if(pin_next==string::npos) {
                            pin_next=0;
                            pin_alpha = pin_str;
                        } else {
                            pin_alpha = pin_str.substr(pos,pin_next-pos);
                        }
                        int pin = atoi( pin_alpha.c_str() );
                        if(bus>=0 ) {
                            // cout << "Bus proc: " << pin_str << '\n';
                            stringstream aux;
                            aux << bus;                            
                            string bus_name=name+"["+aux.str()+"]";
                            p->set_pin( pin, bus_name );
                            pin_str=pin_str.substr(pin_next);
                            if( pin_str.size() > 0 && pin_str[0]==',' ) pin_str=pin_str.substr(1);
                        }
                        else p->set_pin( pin, name );
                    }while( --bus>=0 );
                }
            }
            // cout << "Module " << p->get_name() << " with " << p->pin_count() << " pins.\n";
            comps.insert( pair<string, Component*>(ref_name,p) );
        }
    }
    // cout << comps.size() << " library modules added.\n";
}