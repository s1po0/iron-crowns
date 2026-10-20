#pragma once
// Portable gameplay rules: also compiled outside Unreal by the regression suite.
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <queue>
#include <string>
#include <vector>
namespace Castle
{
constexpr int Size = 40;
constexpr float Tile = 300.0f; // Unreal centimetres, three metres per tile.
enum class Kind { Keep, Stockpile, Woodcutter, Farm, Mill, Bakery, House, Wall, Gate, Barracks, Count };
struct Cell { int x=0, y=0; bool operator==(Cell b) const { return x==b.x && y==b.y; } };
struct Building { int id=0; Kind kind=Kind::Keep; Cell cell; float construction=0, clock=0; bool open=true; };
struct Resources { int wood=220, stone=150, grain=0, flour=0, bread=30, gold=250; };
struct State { int schema=1, mission=0, nextId=1; Resources resources; std::vector<Building> buildings; };
inline const char* Name(Kind k)
{
    constexpr const char* Names[]={"Keep","Stockpile","Woodcutter","Farm","Mill","Bakery","House","Wall","Gate","Barracks"};
    const int n=static_cast<int>(k); return n>=0 && n<10 ? Names[n] : "Unknown";
}
inline const char* MissionName(int m) { return m==1 ? "Southern Bridge" : m==2 ? "Western Gate" : "Green Valley"; }
inline bool ValidKind(Kind k) { return static_cast<int>(k)>=0 && k<Kind::Count; }
inline int Footprint(Kind k) { return k==Kind::Keep || k==Kind::Farm ? 3 : k==Kind::Wall || k==Kind::Gate ? 1 : 2; }
inline std::array<int,2> Cost(Kind k)
{
    constexpr int Costs[10][2]={{0,0},{30,0},{25,0},{35,0},{45,10},{35,10},{35,5},{0,8},{15,20},{50,30}};
    if (!ValidKind(k)) return {0,0};
    const int i=static_cast<int>(k); return {Costs[i][0],Costs[i][1]};
}
inline bool Water(Cell p, int mission)
{
    if(p.x<3 || p.y<3 || p.x>=37 || p.y>=37) return true;
    if(mission==1) return p.y>=25 && p.y<=27 && !(p.x>=18 && p.x<=21);
    if(mission==2) return p.x>=10 && p.x<=12 && !(p.y>=14 && p.y<=17);
    return p.x>=30 && p.x<=32 && !(p.y>=16 && p.y<=18);
}
class Rules
{
public:
    State state;
    explicit Rules(int mission=0) { Reset(mission); }
    void Reset(int mission)
    {
        state=State{}; state.mission=std::clamp(mission,0,2);
        state.resources.wood=state.mission==1 ? 280 : state.mission==2 ? 320 : 220;
        state.resources.stone=state.mission==2 ? 200 : 150;
        state.buildings.push_back({0,Kind::Keep,{18,16},8,0,true});
    }
    static bool Contains(const Building& b, Cell p)
    { const int n=Footprint(b.kind); return p.x>=b.cell.x && p.y>=b.cell.y && p.x<b.cell.x+n && p.y<b.cell.y+n; }
    bool Solid(Cell p) const
    {
        if(Water(p,state.mission)) return true;
        for(const auto& b:state.buildings) if(Contains(b,p) && !(b.kind==Kind::Gate && b.open)) return true;
        return false;
    }
    std::string BuildError(Kind kind, Cell p) const
    {
        if(!ValidKind(kind) || kind==Kind::Keep) return "Choose a building first.";
        if(p.x<3 || p.y<3 || p.x>36 || p.y>36) return "Outside playable map.";
        if(state.nextId>=1000000) return "Building ID limit reached.";
        if(state.buildings.size()>=256) return "Building limit reached.";
        const auto cost=Cost(kind);
        if(state.resources.wood<cost[0] || state.resources.stone<cost[1]) return "Not enough wood or stone.";
        for(int y=0;y<Footprint(kind);++y) for(int x=0;x<Footprint(kind);++x)
        {
            const Cell q{p.x+x,p.y+y};
            if(Water(q,state.mission)) return "Water or map boundary: choose another plot.";
            for(const auto& b:state.buildings) if(Contains(b,q)) return "A building already occupies this plot.";
        }
        return {};
    }
    bool Place(Kind kind, Cell p)
    {
        if(!BuildError(kind,p).empty()) return false;
        const auto cost=Cost(kind); state.resources.wood-=cost[0]; state.resources.stone-=cost[1];
        state.buildings.push_back({state.nextId++,kind,p,0,0,true}); return true;
    }
    bool Suggest(Kind kind, Cell center, Cell& result) const
    {
        // Fixed board bounds keep work bounded, even if the camera center is outside the map.
        int best=1000000; bool found=false;
        center.x=std::clamp(center.x,3,36); center.y=std::clamp(center.y,3,36);
        for(int y=3;y<37;++y) for(int x=3;x<37;++x)
        { const Cell p{x,y}; const int d=std::abs(x-center.x)+std::abs(y-center.y);
          if(d<best && BuildError(kind,p).empty()) { result=p; best=d; found=true; } }
        return found;
    }
    bool Has(Kind kind) const
    { return std::any_of(state.buildings.begin(),state.buildings.end(),[kind](const Building& b){return b.kind==kind && b.construction>=8;}); }
    bool ToggleGate(Cell p)
    { for(auto& b:state.buildings) if(b.kind==Kind::Gate && Contains(b,p) && b.construction>=8) { b.open=!b.open; return true; } return false; }
    void Step(float dt)
    {
        if(!std::isfinite(dt)) return;
        dt=std::clamp(dt,0.0f,0.25f);
        for(auto& b:state.buildings) b.construction=std::min(8.0f,b.construction+dt);
        if(!Has(Kind::Stockpile)) return;
        // Initial inventory economy only. Physical workers/combat are NOT ported yet.
        auto& r=state.resources;
        for(auto& b:state.buildings)
        {
            if(b.construction<8) continue;
            const bool produces=b.kind==Kind::Woodcutter || b.kind==Kind::Farm || b.kind==Kind::Mill || b.kind==Kind::Bakery;
            if(!produces) continue;
            b.clock+=dt; if(b.clock<12) continue; b.clock-=12;
            if(b.kind==Kind::Woodcutter) r.wood=std::min(1000000,r.wood+3);
            if(b.kind==Kind::Farm) r.grain=std::min(1000000,r.grain+3);
            if(b.kind==Kind::Mill && r.grain>=2) { r.grain-=2; r.flour=std::min(1000000,r.flour+2); }
            if(b.kind==Kind::Bakery && r.flour>=2) { r.flour-=2; r.bread=std::min(1000000,r.bread+4); }
        }
    }
    std::vector<Cell> Path(Cell start, Cell goal) const
    {
        if(Solid(start) || Solid(goal)) return {};
        std::array<int,Size*Size> prev; prev.fill(-1); std::queue<Cell> q;
        const auto index=[](Cell p){return p.y*Size+p.x;};
        prev[index(start)]=index(start); q.push(start);
        constexpr Cell offsets[]={{1,0},{-1,0},{0,1},{0,-1}};
        while(!q.empty())
        {
            Cell p=q.front(); q.pop(); if(p==goal) break;
            for(Cell d:offsets) { Cell n{p.x+d.x,p.y+d.y}; if(Solid(n)) continue;
                if(prev[index(n)]==-1) { prev[index(n)]=index(p); q.push(n); } }
        }
        if(prev[index(goal)]<0) return {};
        std::vector<Cell> path; int at=index(goal);
        while(at!=index(start)) { path.push_back({at%Size,at/Size}); at=prev[at]; }
        path.push_back(start); std::reverse(path.begin(),path.end()); return path;
    }
    static bool Validate(const State& s)
    {
        if(s.schema!=1 || s.mission<0 || s.mission>2 || s.nextId<1 || s.nextId>1000000 || s.buildings.empty() || s.buildings.size()>256) return false;
        const auto& r=s.resources;
        for(int n:{r.wood,r.stone,r.grain,r.flour,r.bread,r.gold}) if(n<0 || n>1000000) return false;
        std::array<bool,Size*Size> occupied{}; std::vector<int> ids;
        for(const auto& b:s.buildings)
        {
            if(!ValidKind(b.kind) || b.id<0 || b.id>=s.nextId || std::find(ids.begin(),ids.end(),b.id)!=ids.end()) return false;
            if(!std::isfinite(b.construction) || b.construction<0 || b.construction>8 || !std::isfinite(b.clock) || b.clock<0 || b.clock>=12) return false;
            if(b.cell.x<3 || b.cell.y<3 || b.cell.x>36 || b.cell.y>36) return false;
            if(b.kind==Kind::Keep && (b.id!=0 || !(b.cell==Cell{18,16}) || b.construction!=8)) return false;
            ids.push_back(b.id);
            for(int y=0;y<Footprint(b.kind);++y) for(int x=0;x<Footprint(b.kind);++x)
            { Cell p{b.cell.x+x,b.cell.y+y}; if(Water(p,s.mission)) return false;
              const int i=p.y*Size+p.x; if(occupied[i]) return false; occupied[i]=true; }
        }
        return s.buildings.front().kind==Kind::Keep && s.buildings.front().id==0;
    }
    bool Restore(const State& candidate) { if(!Validate(candidate)) return false; state=candidate; return true; }
};
}
