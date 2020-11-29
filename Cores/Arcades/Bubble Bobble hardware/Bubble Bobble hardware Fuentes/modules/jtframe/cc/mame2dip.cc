#include <iostream>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <string>
#include <list>
#include <set>
#include <vector>
#include <ctype.h>

#include "mamegame.hpp"


using namespace std;


set<string> swapregions;
set<string> fillregions;
set<string> ignoreregions;
map<string,int> startregions;
map<string,int> fracregions;

class DIP_shift {
public:
    string name;
    int shift;
};

class Header {
    int *buf;
    int _size;
    int pos, offset_lut;
    vector<string> regions;
public:
    Header(int size);
    ~Header();
    int get_size() { return _size; }
    int* data() { return buf; }
    void push( int v );
    // Offset list
    bool set_offset_lut( int start ) { offset_lut = start; return start<_size && start>=0; }
    void add_region(const char *s) { regions.push_back(s); }
    bool set_offset( string& s, int offset );
};

typedef list<DIP_shift> shift_list;

void makeMRA( Game* g, string& rbf, string& dipbase, shift_list& shifts,
    const string& buttons, const string& altfolder, Header* header );
void clean_filename( string& fname );
void rename_regions( Game *g, list<string>& renames );

struct ROMorder {
    string region;
    string order;
};

int main(int argc, char * argv[] ) {
    bool print=false;
    string fname="mame.xml";
    string rbf, dipbase("16"), buttons, altfolder;
    bool   fname_assigned=false;
    shift_list shifts;
    Header *header=NULL;
    string region_order;
    list<string> rmdipsw, renames;
    list<ROMorder> rom_order;
try{
    for( int k=1; k<argc; k++ ) {
        string a = argv[k];
        if( a=="-swapbytes" ) {
            while( ++k < argc && argv[k][0]!='-' ) {
                swapregions.insert(argv[k]);
            }
            if( k<argc && argv[k][0]=='-' ) k--;
            continue;
        }
        if( a=="-fill" ) {
            fillregions.insert(string(argv[++k]));
            continue;
        }
        if( a=="-start" ) {
            string reg(argv[++k]);
            int offset=strtol( argv[++k], NULL, 0 );
            startregions[reg]=offset;
            continue;
        }
        if( a=="-dipbase" ) {
            dipbase=argv[++k];
            continue;
        }
        if( a=="-dipshift" ) {
            assert(argc>k+2);
            shifts.push_back( {argv[++k], (int)strtol(argv[++k], NULL,0) });
            continue;
        }
        if( a=="-ignore" ) {
            ignoreregions.insert(string(argv[++k]));
            continue;
        }
        if( a=="-frac" ) {
            string reg(argv[++k]);
            int frac=strtol( argv[++k], NULL, 0 );
            fracregions[reg]=frac;
            continue;
        }
        if( a=="-rbf" ) {
            rbf =argv[++k];
            continue;
        }
        if( a=="-altfolder" ) {
            altfolder = argv[++k];
            continue;
        }
        if( a=="-buttons" ) {
            while( ++k < argc && argv[k][0]!='-' ) {
                if(buttons.size()==0)
                    buttons=argv[k];
                else
                    buttons+=string(" ") + string(argv[k]);
            }
            if( k<argc && argv[k][0]=='-' ) k--;
            continue;
        }
        if( a=="-rmdipsw" ) {
            while( ++k < argc && argv[k][0]!='-' ) {
                rmdipsw.push_back(argv[k]);
            }
            if( k<argc && argv[k][0]=='-' ) k--;
            continue;
        }
        if( a=="-rename" ) {
            while( ++k < argc && argv[k][0]!='-' ) {
                if( strchr( argv[k], '=' )==NULL ) {
                    throw "ERROR: wrong syntax in rename argument\n"
                          "       correct format is newname=oldname\n";
                }
                renames.push_back(argv[k]);
            }
            if( k<argc && argv[k][0]=='-' ) k--;
            continue;
        }
        // Header support
        if( a=="-header" ) {
            if( header!=NULL ) {
                throw "ERROR: header had already been defined\n";

            }
            int aux=strtol(argv[++k], NULL, 0);
            if( aux<=0 || aux>128 ) {
                throw "ERROR: header must be smaller than 128 bytes\n";
            }
            header = new Header(aux);
            continue;
        }
        if( a=="-header-data" ) {
            if( header==NULL) {
                throw "ERROR: header size has not been defined\n";
            }
            while( ++k<argc && argv[k][0]!='-' ) {
                int aux=strtol(argv[k], NULL, 0);
                if( aux<0 || aux>255 ) {
                    throw "ERROR: header data must be written in possitive bytes\n";
                }
                header->push(aux);
            }
            if( k<argc && argv[k][0]=='-' ) k--;
            continue;
        }
        if( a=="-header-offset" ) {
            if( header==NULL) {
                throw "ERROR: header size has not been defined\n";
            }
            assert( ++k < argc );
            int aux = strtol( argv[k], NULL, 0);
            if( !header->set_offset_lut( aux ) ) {
                throw "ERROR: header offset LUT is out of bounds\n";
            }
            while( ++k<argc && argv[k][0]!='-') header->add_region(argv[k]);
            continue;
        }
        // ROM order
        if( a=="-order" ) {
            while( ++k < argc && argv[k][0]!='-' ) {
                region_order = region_order + argv[k] + string(" ");
            }
            if( k<argc && argv[k][0]=='-' ) k--;
            continue;
        }
        if( a=="-order-roms" ) {
            assert( ++k < argc );
            ROMorder o;
            o.region = argv[k];
            while( ++k < argc && argv[k][0]!='-' ) {
                o.order = o.order + argv[k] + string(" ");
            }
            if( k<argc && argv[k][0]=='-' ) k--;
            rom_order.push_back(o);
            continue;
        }
        // Help
        if( a == "-help" || a =="-h" ) {
            cout << "mame2dip: converts MAME XML dump to MRA format\n"
                    "          by Jose Tejada. Part of JTFRAME\n"
                    "Usage:\n"
                    "          first argument:  path to file containing 'mame -listxml' output\n"
                    "    -rbf       <name>          set RBF file name\n"
                    "    -buttons   shoot jump etc  Gives names to the input buttons\n"
                    "    -altfolder path            Path where MRA for clone games will be added\n"
                    "\n DIP options\n"
                    "    -dipbase   <number>        First bit to use as DIP setting in MiST status word\n"
                    "    -dipshift  <name> <number> Shift bits of DIPSW name by given ammount\n"
                    "    -rmdipsw   <name> ...      Deletes the give DIP switch from the output MRA\n"
                    "\n Region options\n"
                    "    -order     regions         define the dump order of regions. Those not enumerated\n"
                    "                               will get dumped last\n"
                    "    -order-roms region # # #   ROMs of specified regions are re-ordered. Index starts\n"
                    "                               with zero. Unspecified ROMs will not be used.\n"
                    "    -ignore    <region>        ignore a given region\n"
                    "    -start     <region>        set start of region in MRA file\n"
                    "    -swapbytes <region>        swap bytes for named region\n"
                    "    -frac      <region> <#>    divide region in fractions\n"
                    "    -fill      <region>        fill gaps between files within region\n"
                    "    -rename    old=new?        rename region old by new. Add ? to skip warning messages\n"
                    "                               if old is not found.\n"
                    "\n Header options \n"
                    "    -header    size            Defines an empty (zeroes) header of the given size\n"
                    "    -header-data value         Pushes data to the header. It can be defined multiple times\n"
                    "    -header-offset start regions\n"
                    "                               Start is the first byte where the regions offsets will be dumped\n"
                    "                               The bottom 8 bits of the offsets are dropped. Each offset is written\n"
                    "                               as two bytes. \"regions\" is a list of words with the MAME name of\n"
                    "                               the ROM regions\n"
            ;
            return 0;
        }
        if( !fname_assigned ) {
            fname = argv[k];
            fname_assigned = true;
        } else {
            cout << "Unknown argument " << argv[k] << "\n";
            throw "ERROR\n";
        }
    }
} catch( const char *s ) {
    cout << s;
    delete header;
    return 1;
}
    GameMap games;
    parse_MAME_xml( games, fname.c_str() );
    for( auto& g : games ) {
        Game* game=g.second;
        // Rename ROM regions
        rename_regions( game, renames );
        // Remove unused dip swithces
        ListDIPs& dips=game->getDIPs();
        list<ListDIPs::iterator> todelete;
        if( rmdipsw.size()>0 ) {
            for( ListDIPs::iterator k=dips.begin(); k!=dips.end(); k++ ) {
                DIPsw* sw = *k;
                for( auto s : rmdipsw ) {
                    if( sw->name == s ) {
                        todelete.push_back(k);
                        break;
                    }
                }
            }
        }
        for( auto k : todelete ) {
            delete *k;
            dips.erase(k);
        }
        cout << game->name << '\n';
        // Sort ROMs
        for( auto o : rom_order ) {
            ROMRegion* region = game->getRegion( o.region, false );
            if( region==NULL ) {
                cout << "WARNING: order-roms argument cannot be applied to " << game->name << '\n';
                break;
            }
            region->sort(o.order.c_str());
        }
        game->sortRegions(region_order.c_str());
        makeMRA(game, rbf, dipbase, shifts, buttons, altfolder, header );
    }
    delete header; header=NULL;
    return 0;
}

void rename_regions( Game *g, list<string>& renames ) {
    ListRegions& regions = g->getRegionList();
    for( string& s : renames ) {
        size_t strpos = s.find_first_of('=');
        string newname = s.substr(0, strpos);
        string oldname = s.substr(strpos+1);
        bool found=false, nowarning=false;
        if( oldname[oldname.size()-1]=='?' ) {
            nowarning = true;
            oldname = oldname.substr(0, oldname.size()-1);
        }
        for( ROMRegion* reg : regions ) {
            if( reg->name == oldname ) {
                reg->name=newname;
                found=true;
                break;
            }
        }
        if( !found && !nowarning) {
            cout << "Warning: renamed failed for " << g->name << " region '" << oldname << "'. It was not found\n";
        }
    }
}

void replace( string&aux, const char *find_text, const char* new_text ) {
    int pos;
    int n = strlen(find_text);
    while( (pos=aux.find(find_text))!=string::npos ) {
        aux.replace(pos,n,new_text);
    }
}

struct Attr {
    string name, value;
};

class Node {
    list<Node*> nodes;
    list<Attr*> attrs;
    bool is_comment;
public:
    string name, value;
    Node( string n, string v="" );
    Node& add( string n, string v="");
    Node& add_front( string n, string v="");
    void add_attr( string n, string v="");
    void dump(ostream& os, string indent="" );
    void comment( string v );
    virtual ~Node();
};

void makeROM( Node& root, Game* g, Header* header ) {
    Node& n = root.add("rom");
    n.add_attr("index","0");
    string zips = g->name+".zip";
    if( g->cloneof.size() ) {
        zips = zips + "|" + g->cloneof+".zip";
    }
    n.add_attr("zip",zips);
    n.add_attr("type","merged");
    n.add_attr("md5","None"); // important or MiSTer will not let the game boot
    int dumped=0;
    g->moveRegionBack("proms"); // This region should appear last
    for( ROMRegion* region : g->getRegionList() ) {
        if ( ignoreregions.count(region->name)>0 ) continue;
        auto start_offset = startregions.find(region->name);
        if( start_offset != startregions.end() ) {
            int s = start_offset->second;
            int rep = s-dumped;
            if( rep<0 ) {
                cout << "WARNING: required start value is too low for "
                " region " << region->name << '\n';
            } else if( rep>0 ) {
                Node& fill = n.add("part","FF");
                char buf[32];
                snprintf(buf,32,"0x%X",rep);
                fill.add_attr("repeat",buf);
                dumped=s;
            }
        }
        char title[128];
        snprintf(title,128,"%s - starts at 0x%X", region->name.c_str(), dumped );
        if( header ) header->set_offset( region->name, dumped );
        n.comment( title );
        bool swap = swapregions.count(region->name)>0;
        bool fill = fillregions.count(region->name)>0;
        // is it a fractioned region?
        auto frac_idx = fracregions.find(region->name);
        int frac=0;
        if( frac_idx!= fracregions.end() ) {
            frac = frac_idx->second;
        }
        string frac_output="0";
        switch( frac ) {
            case 2: frac_output="16"; break;
            case 4: frac_output="32"; break;
            case 0: break;
            default: cout << "WARNING: unsupported frac value for region "
                          << region->name << "\n";
                     continue;
        }
        if( frac==0 ) {
            int offset=0;
            for( ROM* r : region->roms ) {
                // Fill in gaps between ROM chips
                if( offset != r->offset && fill) {
                    Node& part = n.add("part","FF");
                    int rep = r->offset - offset;
                    char buf[32];
                    snprintf(buf,32,"0x%X",rep);
                    part.add_attr("repeat",buf);
                    dumped += rep;
                }
                Node& parent = swap ? n.add("interleave") : n;
                if( swap ) {
                    parent.add_attr("output","16");
                }
                Node& part = parent.add("part");
                part.add_attr("name",r->name);
                part.add_attr("crc",r->crc);
                if( swap ) {
                    part.add_attr("map","12");
                }
                offset = r->offset + r->size;
                dumped += r->size;
            }
        } else {
            // Fractioned ROMs
            // First check that the count is correct
            if( region->roms.size()%frac != 0 ) {
                cout << "WARNING: Total number of ROM entries does not much fraction value"
                    " for region " << region->name << "\n";
                continue;
            }
            const int roms_size = region->roms.size();
            ROM** roms = new ROM*[roms_size];
            int aux=0;
            int step=roms_size/frac;
            for( ROM* r : region->roms ) roms[aux++] = r;
            // Dump ROMs
            for( aux=0; aux<roms_size/frac; aux++ ) {
                Node& inter=n.add("interleave");
                inter.add_attr("output",frac_output);
                for( int chunk=0; chunk<frac; chunk++) {
                    ROM*r = roms[aux+chunk*step];
                    Node& part = inter.add("part");
                    part.add_attr("name",r->name);
                    part.add_attr("crc",r->crc);
                    char *mapping = new char[frac+1];
                    for( int k=0; k<frac; k++ ) mapping[k]='0';
                    mapping[frac]=0;
                    mapping[frac-1-chunk]='1';
                    part.add_attr("map",mapping);
                    delete[] mapping;
                    dumped += r->size;
                }
            }
            delete[] roms;
        }
    }
    char endsize[128];
    snprintf(endsize,128,"Total 0x%X bytes - %d kBytes",dumped,dumped>>10);
    n.comment(endsize);
    // Process header
    if( header ) {
        stringstream ss;
        int *b = header->data();
        for( int k=0; k<header->get_size(); k++ ) {
            if( k>0 && (k%8==0) )
                ss << '\n';
            if( k%8==0 ) ss << "        ";
            ss << hex << setfill('0') << setw(2)  << b[k] << ' ';
        }
        Node& h = n.add_front("part", ss.str() );
    }
}

void makeDIP( Node& root, Game* g, string& dipbase, shift_list& shifts ) {
    ListDIPs& dips=g->getDIPs();
    int base=-8;
    bool ommit_parenthesis=true;
    string last_tag, last_location;
    int cur_shift=0;
    if( dips.size() ) {
        Node& n = root.add("switches");
        n.add_attr("default","FF,FF");
        n.add_attr("base",dipbase);
        for( DIPsw* dip : dips ) {
            if( dip->tag != last_tag /*|| dip->location != last_location*/ ) {
                n.comment( dip->tag );
                //if( last_tag.size() )
                base+=8;
                last_tag = dip->tag;
                last_location = dip->location;
                // cout << "base = " << base << "\ntag " << dip->tag << "\nlocation " << dip->location << '\n';
                // Look for shift
                cur_shift = 0;
                for( auto& k : shifts) {
                    if( k.name == dip->tag ) {
                        cur_shift = k.shift;
                        break;
                    }
                }
            }
            Node &dipnode = n.add("dip");
            dipnode.add_attr("name",dip->name);
            // Bits
            int bit0 = base;
            int bit1 = base;
            int m    = dip->mask;
            int k;
            for( k=0; k<32; k++ ) {
                if( (m&1) == 0 ) {
                    m>>=1;
                    bit0++;
                }
                else
                    break;
            }
            for( bit1=bit0; k<32;k++ ) {
                if( (m&1) == 1 ) {
                    m>>=1;
                    bit1++;
                }
                else
                    break;
            }
            --bit1;
            //if( bit0 > base ) bit0-=base;
            //if( bit1 > base ) bit1-=base;
            // apply shift
            bit0 -= cur_shift;
            bit1 -= cur_shift;
            stringstream bits;
            if( bit1==bit0 )
                bits << dec << bit0;
            else
                bits << dec << bit0 << "," << bit1;
            dipnode.add_attr("bits",bits.str());
            // Add DIP configuration values
            stringstream ids;
            for( DIPvalue& dval : dip->values ) {
                string aux = dval.name;
                if( ommit_parenthesis ) {
                    while(1) {
                        int x = aux.find_first_of('(');
                        if( x!=string::npos) {
                            int y = aux.find_first_of(')');
                            if( y!=string::npos) {
                                aux = aux.substr(0,x)+aux.substr(y+1);
                            } else break;
                        } else break;
                    }
                }
                replace( aux, "0000", "0k");
                replace( aux, " Coins", "");
                replace( aux, " Coin", "");
                replace( aux, " Credits", "");
                replace( aux, " Credit", "");
                if( aux[aux.length()-1]==' ' ) {
                    aux.erase( aux.end()-1 );
                }
                ids << aux << ',';
            }
            string ids_str = ids.str();
            ids_str.erase( ids_str.length()-1, 1 ); // delete final comma
            dipnode.add_attr("ids",ids_str);
        }
    }
}

void makeJOY( Node& root, Game* g, string buttons ) {
    Node& n = root.add("buttons");
    if( buttons.size()==0 ) {
        buttons="Fire Jump";
    }
    string names,mapped;
    int count=0;
    const char *pad_buttons[]={"Y","X","B","A","L","R","Select","Start"};
    size_t last=0, pos = buttons.find_first_of(' ');
    do {
        if(count>0) {
            names+=",";
            mapped+=",";
        }
        buttons[last] = toupper( buttons[last] );
        names  += pos==string::npos ? buttons.substr(last) : buttons.substr(last,pos-last);
        mapped += pad_buttons[count];
        if(pos==string::npos) break;
        last=pos+1;
        pos=buttons.find_first_of(' ', last);
        count++;
    } while(true);
    if( count>4 ) {
        cout << "ERROR: more than four buttons were defined. That is not supported yet.\n";
        cout << "       start, coin and pause will not be automatically added\n";
    } else {
        names +=",Start,Coin,Pause";
        mapped+=",R,L,Start";
    }
    n.add_attr("names",names.c_str());
    n.add_attr("default",mapped.c_str());
}

void makeMOD( Node& root, Game* g ) {
    int mod_value = 0;
    if( g->rotate!=0 ) {
        root.comment("Vertical game");
        mod_value |= 1;
    }
    char buf[4];
    snprintf(buf,4,"%02X",mod_value);
    Node& mod=root.add("rom");
    mod.add_attr("index","1");
    Node& part = mod.add("part",buf);

}

void makeMRA( Game* g, string& rbf, string& dipbase, shift_list& shifts,
    const string& buttons, const string& altfolder,
    Header* header ) {
    string indent;
    Node root("misterromdescription");

    Node& about = root.add("about","");
    about.add_attr("author","jotego");
    about.add_attr("webpage","https://patreon.com/topapate");
    about.add_attr("source","https://github.com/jotego");
    about.add_attr("twitter","@topapate");

    root.add("name",g->description);
    root.add("setname",g->name);
    if( rbf.length()>0 ) {
        root.add("rbf",rbf);
    }

    makeROM( root, g, header );
    makeMOD( root, g );
    makeDIP( root, g, dipbase, shifts );
    makeJOY( root, g, buttons );

    string fout_name = g->description;
    clean_filename(fout_name);
    fout_name+=".mra";
    // MRA file for a clone is created in a subfolder - if specified
    if( g->cloneof.size() && altfolder.size() ) {
        fout_name = altfolder + "/" + fout_name;
    }
    ofstream fout(fout_name);
    if( !fout.good() ) {
        cout << "ERROR: cannot create " << fout_name << '\n';
        return;
    }
    fout <<
"<!--          FPGA compatible core of arcade hardware by Jotego\n"
"\n"
"              This core is available for hardware compatible with MiST and MiSTer\n"
"              Other FPGA systems may be supported by the time you read this.\n"
"              This work is not mantained by the MiSTer project. Please contact the\n"
"              core author for issues and updates.\n"
"\n"
"              (c) Jose Tejada, 2020. Please support the author\n"
"              Patreon: https://patreon.com/topapate\n"
"              Paypal:  https://paypal.me/topapate\n"
"\n"
"              The author does not endorse or participate in illegal distribution\n"
"              of copyrighted material. This work can be used with legally\n"
"              obtained ROM dumps or with compatible homebrew software\n"
"\n"
"              This file license is GNU GPLv2.\n"
"              You can read the whole license file in\n"
"              https://opensource.org/licenses/gpl-2.0.php\n"
"\n"
"-->\n\n";
    root.dump(fout);
}

Node& Node::add( string n, string v ) {
    Node *nd = new Node(n, v);
    nodes.push_back(nd);
    return *nd;
}

Node& Node::add_front( string n, string v ) {
    Node *nd = new Node(n, v);
    nodes.push_front(nd);
    return *nd;
}

void Node::add_attr( string n, string v) {
    Attr* a = new Attr({n,v});
    attrs.push_back(a);
}

void Node::comment( string v ) {
    Node *nd = new Node(v);
    nodes.push_back(nd);
    nd->is_comment = true;
}

void Node::dump(ostream& os, string indent ) {
    if( is_comment ) {
        os << indent << "<!-- " << name << " -->\n";
    }
    else {
        os << indent << "<" << name;
        if( attrs.size() ) {
            for( Attr* a : attrs ) {
                os << " " << a->name << "=\"" << a->value << '\"';
            }
        }
        if( nodes.size() || value.size() ) {
            os << ">";
            if( !nodes.size()) {
                string aux = value.size()>80 ? "\n" : "";
                os << aux;
                os << value << aux;
                if( value.find_first_of('\n')!=string::npos ) os << indent;
            } else {
                os << '\n';
                for( Node* n : nodes ) {
                    n->dump(os, indent+"    ");
                }
                os << indent;
            }
            os << "</" << name << ">\n";
        } else {
            os << "/>\n";
        }
    }
}

Node::~Node() {
    for( Node* n: nodes ) delete n;
    for( Attr* a: attrs ) delete a;
}

void clean_filename( string& fname ) {
    if( fname.size()==0 ) {
        fname="no-description";
        cout << "ERROR: no description in XML file\n";
        return;
    }
    char *s = new char[ fname.size()+1 ];
    char *c = s;
    for( int k=0; k<fname.size(); k++ ) {
        if( fname[k]=='/' ) {
            *c++='-';
        } else
        if( fname[k]>=32 && fname[k]!='\'' && fname[k]!=':') {
            *c++=fname[k];
        }
    }
    *c=0;
    // Remove trailing blanks
    while( *--c==' ' || *c=='\t' ) {
        *c=0;
    }
    fname=s;
    delete[]s;
}

Header::Header(int size ) {
    buf = new int[size];
    _size = size;
    pos=0;
}

Header::~Header() {
    delete []buf;
    buf=NULL;
}

void Header::push(int v) {
    if(pos<_size-1) buf[pos++] = v;
}

bool Header::set_offset( string& s, int offset ) {
    int k=0;
    bool found=false;
    while( k<regions.size() ) {
        if( regions[k]==s ) {
            found=true;
            break;
        }
        k++;
    }
    if( found ) {
        int j=offset_lut+k*2;
        if( j+2 >= _size ) return false;
        offset>>=8;
        buf[j++] = (offset>>8)&0xff;
        buf[j]   = offset&0xff;
        return true;
    }
    return false;
}

Node::Node( string n, string v ) : name(n), value(v), is_comment(false) {
    while(v.back()==' ') v.pop_back();
}