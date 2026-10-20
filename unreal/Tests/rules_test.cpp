#include "CastleRules.h"
#include <cassert>
#include <climits>
#include <iostream>
#include <limits>
using namespace Castle;
int main()
{
    for(int mission=0;mission<3;++mission)
    {
        Rules r(mission); assert(Rules::Validate(r.state));
        auto old=r.state.resources.wood;
        assert(!r.Place(Kind::Farm,{18,16}) && r.state.resources.wood==old);
        assert(!r.Place(Kind::Farm,{INT_MAX,INT_MAX}));
        assert(!r.Place(Kind::Keep,{8,8}));
        assert(!r.Place(Kind(100),{8,8}));
        Cell farm; assert(r.Suggest(Kind::Farm,{19,19},farm));
        assert(r.Place(Kind::Farm,farm) && r.state.resources.wood==old-35);
        assert(!r.Place(Kind::Farm,farm));
        for(int i=0;i<100;++i) r.Step(.25f);
        assert(r.state.resources.grain==0); // no stockpile, no magic production
        Cell depot; assert(r.Suggest(Kind::Stockpile,{14,20},depot)); assert(r.Place(Kind::Stockpile,depot));
        Cell mill; assert(r.Suggest(Kind::Mill,{23,23},mill)); assert(r.Place(Kind::Mill,mill));
        Cell bakery; assert(r.Suggest(Kind::Bakery,{26,23},bakery)); assert(r.Place(Kind::Bakery,bakery));
        for(int i=0;i<1000;++i) r.Step(.25f);
        assert(r.state.resources.bread>30 && Rules::Validate(r.state));
        State snap=r.state; Rules loaded; assert(loaded.Restore(snap));
        assert(loaded.state.mission==mission && loaded.state.resources.bread==snap.resources.bread);
        State bad=snap; bad.buildings.push_back(bad.buildings.back()); assert(!loaded.Restore(bad));
        assert(loaded.state.buildings.size()==snap.buildings.size());
        bad=snap; bad.resources.wood=-1; assert(!loaded.Restore(bad));
        bad=snap; bad.mission=99; assert(!loaded.Restore(bad));
        bad=snap; bad.schema=2; assert(!loaded.Restore(bad));
        bad=snap; bad.buildings[0].construction=std::numeric_limits<float>::quiet_NaN(); assert(!loaded.Restore(bad));
        bad=snap; bad.buildings.back().cell={INT_MAX,INT_MAX}; assert(!loaded.Restore(bad));
        bad=snap; bad.buildings.back().kind=Kind(999); assert(!loaded.Restore(bad));
        bad=snap; bad.nextId=0; assert(!loaded.Restore(bad));
        loaded.Step(std::numeric_limits<float>::infinity()); assert(Rules::Validate(loaded.state));
        Rules roads(mission);
        Cell across=mission==1 ? Cell{8,30} : mission==2 ? Cell{7,10} : Cell{34,10};
        auto path=roads.Path(across,{21,17}); assert(!path.empty());
        assert((path.front()==across) && (path.back()==Cell{21,17}));
        for(auto p:path) assert(!roads.Solid(p));
        assert(roads.Path({INT_MIN,INT_MAX},{21,17}).empty());
        Cell gate={25,12}; assert(roads.Place(Kind::Gate,gate));
        assert(!roads.ToggleGate(gate));
        for(int i=0;i<32;++i) roads.Step(.25f);
        assert(!roads.Solid(gate)); assert(roads.ToggleGate(gate)); assert(roads.Solid(gate));
        assert(roads.ToggleGate(gate)); assert(!roads.Solid(gate));
    }
    assert(Water({31,10},0) && !Water({31,10},1) && !Water({31,10},2));
    assert(Water({8,26},1) && !Water({8,26},0));
    assert(Water({11,10},2) && !Water({11,10},0));
    Rules exhausted; exhausted.state.nextId=1000000;
    assert(Rules::Validate(exhausted.state) && !exhausted.Place(Kind::Farm,{8,8}));
    Rules bounded; bounded.state.resources.wood=0; Cell p; assert(!bounded.Suggest(Kind::Farm,{INT_MIN,INT_MAX},p));
    std::cout<<"UNREAL_PORTABLE_RULES_PASS (not Unreal Engine compilation)\n";
}
