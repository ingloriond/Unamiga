#include "mamegame.hpp"
#include <xercesc/sax2/XMLReaderFactory.hpp>

#include <iostream>
#include <iomanip>
#include <sstream>
#include <map>
#include <list>
// Other include files, declarations, and non-Xerces-C++ initializations.

using namespace xercesc;
using namespace std;

string get_str_attr( const Attributes & attrs, const char* name ) {
    const char *blank="";
    const XMLCh* v = attrs.getValue( (const XMLCh*)XMLStr(name) );
    if( v != NULL ) {
        string aux( (const char*)StdStr(v) );
        return aux;
    }
    else return blank;
}

#define TOSTR(a,b) string a( (const char*)StdStr(b) )
//#define GET_STR_ATTR( a ) string a( (const char*)StdStr( attrs.getValue(XMLStr(#a)) ) );
#define GET_STR_ATTR( a ) string a( get_str_attr(attrs, #a) );

void MameParser::startElement( const XMLCh *const uri,
        const XMLCh *const localname, const XMLCh *const qname, const Attributes & attrs )
{
    TOSTR( _localname, localname );
    current_element = _localname;
    if( _localname == "machine" ) {
        GET_STR_ATTR( name );
        string cloneof;
        const XMLCh* aux = attrs.getValue( XMLStr("cloneof"));
        if( aux ) cloneof = (const char*)StdStr(aux);
        current = new Game(name);
        current->cloneof = cloneof;
        games[name] = current;
    }
    if( _localname == "dipswitch" ) {
        GET_STR_ATTR( name );
        GET_STR_ATTR( tag  );
        GET_STR_ATTR( mask );
        current_dip = new DIPsw( name, tag, toint(mask));
        current->addDIP( current_dip );
    }
    if( _localname == "dipvalue" ) {
        GET_STR_ATTR( name );
        GET_STR_ATTR( value );
        current_dip->values.push_back( { name, toint(value)} );
    }
    if( _localname == "diplocation" ) {
        GET_STR_ATTR( name );
        current_dip->location=name;
    }
    if( _localname == "rom" ) {
        parse_rom( attrs );
    }
    if( _localname == "display" ) {
        GET_STR_ATTR( rotate );
        current->rotate = atol(rotate.c_str());
    }
}

void MameParser::endElement( const XMLCh *const uri,
        const XMLCh *const localname, const XMLCh *const qname ) {
    TOSTR( _localname, localname );
    if( _localname == "dipswitch" ) {
        current_dip->values.sort();
        current_dip = nullptr;
    }
}

void MameParser::characters(const XMLCh *const chars, const XMLSize_t length) {
    XMLCh* copy = new XMLCh[length+1];
    copy[0] = 0;
    for(int k=0; k<length; k++ ) {
        copy[k] = chars[k]>32 && chars[k] != '$' ? chars[k] : 0;
    }
    copy[length] = 0;
    TOSTR( _chars, chars );
    if( current_element == "description" && length>3 ) {
        //cout << "Description chunk " << _chars << " - length " << length << '\n';
        current->description += _chars;
    }
    delete[] copy;
}

void MameParser::parse_rom( const Attributes & attrs ) {
    GET_STR_ATTR( name   );
    GET_STR_ATTR( crc    );
    GET_STR_ATTR( region );
    GET_STR_ATTR( size   );
    GET_STR_ATTR( offset );
    ROMRegion* r = current->getRegion( region );
    r->roms.push_back(
        new ROM( {name, crc, toint(size,10), toint(offset,16)} )
    );
}

void Game::moveRegionBack(std::string name) {
    for( ListRegions::iterator k=regions.begin(); k!=regions.end(); k++ ) {
        ROMRegion* tomove = *k;
        if( tomove->name==name ) {
            regions.erase(k);
            regions.push_back(tomove);
            break;
        }
    }
}

ROMRegion* Game::getRegion( std::string _name, bool create ) {
    static ROMRegion *last = nullptr;
    if( last != nullptr && create ) {
        if( last->name == _name ) return last;
    }
    for( ROMRegion *r : regions ) {
        if( r->name == _name ) {
            last = r;
            return last;
        }
    }
    if( create ) {
        last = new ROMRegion( {_name} );
        // cout << "Created region " << _name << '(' << last << ")\n";
        regions.push_back(last);
        return last;
    } else {
        return nullptr;
    }
}

void Game::addDIP( DIPsw* d ) {
    dips.push_back(d);
}

void Game::dump() {
    cout << name << '\n';
    for( auto k : dips ) {
        cout << '\t' << k->name << '\t' << k->tag << '\t' << hex << k->mask << '\n';
    }
}

Game::~Game() {
    for( auto k : dips ) {
        delete k;
    }
    for( auto k : regions ) {
        delete k;
    }
}

int toint(string s, int base) {
    return strtol( s.c_str(), NULL, base);
}

GameMap::~GameMap() {
    for( auto& g : *this ) {
        delete g.second;
        g.second=nullptr;
    }
    clear();
}

ROMRegion::~ROMRegion() {
    for( ROM* r : roms ) {
        delete r;
    }
    roms.clear();
}

int parse_MAME_xml( GameMap& games, const char *xmlFile ) {
    try {
        XMLPlatformUtils::Initialize();
    }
    catch (const XMLException& toCatch) {
        // Do your failure processing here
        return 1;
    }

    SAX2XMLReader* parser = XMLReaderFactory::createXMLReader();

    MameParser mame(games);
    parser->setErrorHandler(&mame);
    parser->setContentHandler( (ContentHandler*) &mame);

    try {
        parser->parse(xmlFile);
    }
    catch (const XMLException& toCatch) {
        char* message = XMLString::transcode(toCatch.getMessage());
        cout << "ERROR (XML): \n"
             << message << "\n";
        XMLString::release(&message);
        return -1;
    }
    catch (const SAXParseException& toCatch) {
        char* message = XMLString::transcode(toCatch.getMessage());
        cout << "ERROR (XML): \n"
             << message << "\n";
        XMLString::release(&message);
        return -1;
    }
    catch (...) {
        cout << "Unexpected Exception \n" ;
        return -1;
    }

    delete parser;
    XMLPlatformUtils::Terminate();
    return 0;
}

void Game::sortRegions(const char *order) {
    int len;
    if( order==NULL || (len=strlen(order))==0 ) return;
    ListRegions sorted;
    char *copy = new char[ len+1 ];
    char *aux;
    strcpy( copy, order );
    aux = strtok( copy, " ");
    while( aux!= NULL ) {
        for(ListRegions::iterator k =regions.begin(); k!=regions.end(); k++ ) {
            class ROMRegion* cur = (*k);
            if( cur->name == aux ) {
                sorted.push_back(cur);
                regions.erase(k);
                break;
            }
        }
        aux=strtok(NULL, " ");
    }
    // copy the rest of the list
    while(regions.size()>0) {
        sorted.push_back(regions.front());
        regions.pop_front();
    }
    regions.swap(sorted);
    delete[] copy;
}

void ROMRegion::sort(const char *order) {
    int len;
    if( order==NULL || (len=strlen(order))==0 ) return;
    ListROMs sorted;
    char *copy = new char[ len+1 ];
    char *aux;
    strcpy( copy, order );
    aux = strtok( copy, " ");
    map<int,ROM*> mapped;
    int k=0;
    for( ROM* r : roms ) {
        mapped[k++]=r;
        //cout << r->name << " - ";
    }
    //cout << '\n';
    while( aux!= NULL ) {
        int i = strtol(aux,NULL,0);
        auto found = mapped.find(i);
        if( found==mapped.end() ) {
            cout << "Warning: requested ROM for ROM ordering is out of bounds\n";
            cout << "         looking for " << i << '\n';
        } else {
            sorted.push_back( found->second );
        }
        aux=strtok(NULL, " ");
    }
    roms.swap(sorted);
    //for(ROM*r:roms) cout << r->name << " - ";
    //cout << '\n';
    delete[] copy;
}