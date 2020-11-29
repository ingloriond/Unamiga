#ifndef _MAMEGAME_HPP

#include <xercesc/sax/HandlerBase.hpp>
#include <xercesc/sax2/DefaultHandler.hpp>
#include <xercesc/sax2/Attributes.hpp>
#include <xercesc/util/XMLString.hpp>

#include <map>
#include <list>
#include <string>

using namespace xercesc;


int toint(std::string s, int base=10);

typedef std::list<class ROM*> ListROMs;
typedef std::list<class ROMRegion*> ListRegions;

class ROM {
public: // keep the variable order:
    std::string name, crc;
    int size, offset;
};


class ROMRegion {
public:
    std::string name;
    ListROMs roms;
    ~ROMRegion();
    void sort(const char *order);
};


class DIPvalue{
public:
    std::string name;
    int val;
    bool operator<(const DIPvalue& x) const { return val < x.val; }
};

typedef std::list<DIPvalue> ListDIPValues;
typedef std::list<class DIPsw*>   ListDIPs;

class DIPsw {
public:
    ListDIPValues values;
    std::string name, tag, location;
    int mask;
    DIPsw( std::string n, std::string t, int m ) :
        name(n), tag(t), mask(m) { }
};

class Game {
    std::list<DIPsw*> dips;
    ListRegions regions;
public:
    std::string name, description, cloneof;
    int rotate;
    Game( std::string _name ) : name(_name), rotate(0) {}
    ~Game();

    void addDIP( DIPsw* d );
    void dump();
    ListDIPs& getDIPs() { return dips; }
    ROMRegion* getRegion( std::string _name, bool create=true );
    ListRegions& getRegionList() { return regions; }
    void sortRegions(const char *order);
    void moveRegionBack(std::string name);
};

class GameMap : public std::map<std::string,Game*> {
public:
    GameMap() {}
    ~GameMap();
};

int parse_MAME_xml( GameMap& games, const char *xmlFile );

class MameParser : public DefaultHandler {
    Game *current;
    DIPsw* current_dip;
    GameMap& games;
    void parse_rom( const Attributes & attrs );
    std::string current_element;
public:
    MameParser(GameMap& _games) : games(_games) {
        current = nullptr;
    }
    // void startDocument();
    // void endDocument();
    void startElement   ( const XMLCh *const uri,
        const XMLCh *const localname,
        const XMLCh *const qname,
        const Attributes & attrs
    );
    void endElement( const XMLCh *const uri,
        const XMLCh *const localname, const XMLCh *const qname );
    void characters(const XMLCh *const chars, const XMLSize_t length);
};


class XMLStr {
    XMLCh* v;
public:
    XMLStr( const char *s ) {
        v = XMLString::transcode( s );
    }
    ~XMLStr() { XMLString::release(&v); }
    operator const XMLCh*() const{ return v; }
};

class StdStr {
    char * v;
public:
    StdStr( const XMLCh *s ) {
        v = XMLString::transcode(s);
    }
    ~StdStr() { XMLString::release(&v); }
    operator const char*() const{ return v; }
};

std::string get_str_attr( const XMLCh* name );

#endif