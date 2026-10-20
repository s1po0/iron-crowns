#include "CastleRuntime.h"
#include "Engine/Canvas.h"
#include "Engine/Engine.h"
void ACastleHUD::DrawHUD()
{
    Super::DrawHUD(); if(!Canvas) return;
    auto* PC=Cast<ACastleController>(PlayerOwner); if(!PC) return;
    Buttons.Reset(); const float S=FMath::Min(Canvas->SizeX/1280.f,Canvas->SizeY/720.f);
    const float OX=(Canvas->SizeX-1280*S)*.5f, OY=(Canvas->SizeY-720*S)*.5f;
    auto Text=[&](const FString& T,float X,float Y,FLinearColor C=FLinearColor::White)
    { DrawText(T,C,OX+X*S,OY+Y*S,GEngine->GetSmallFont(),1.25f*S,false); };
    DrawRect(FLinearColor(.025,.04,.04,.95),OX,OY,1280*S,100*S);
    const auto& R=PC->Rules.state.resources;
    Text(FString::Printf(TEXT("IRON CROWNS / UNREAL PROTOTYPE — %s"),UTF8_TO_TCHAR(Castle::MissionName(PC->Rules.state.mission))),16,12);
    Text(FString::Printf(TEXT("Wood %d   Stone %d   Grain %d   Flour %d   Bread %d   Gold %d"),R.wood,R.stone,R.grain,R.flour,R.bread,R.gold),16,36);
    Text(TEXT("WASD / drag: pan   Wheel / pinch: zoom   Plot > Build. Save/Load are separate from Godot."),16,62,FLinearColor(.8,.8,.6));
    DrawRect(FLinearColor(.025,.04,.04,.95),OX,OY+496*S,1280*S,224*S);
    Text(PC->Notice,16,510,FLinearColor(1,.85,.5));
    Text(FString::Printf(TEXT("Selected: %s   Cost: %d wood / %d stone. Stockpile enables the initial inventory economy."),UTF8_TO_TCHAR(Castle::Name(PC->Chosen)),Castle::Cost(PC->Chosen)[0],Castle::Cost(PC->Chosen)[1]),16,540);
    const TCHAR* Actions[]={TEXT("Stockpile"),TEXT("Woodcutter"),TEXT("Farm"),TEXT("Mill"),TEXT("Bakery"),TEXT("House"),TEXT("Wall"),TEXT("Gate"),TEXT("Barracks"),TEXT("Build"),TEXT("Suggest"),TEXT("Toggle gate"),TEXT("Save"),TEXT("Load"),TEXT("Next map")};
    for(int i=0;i<15;++i)
    {
        const int Row=i/8, Column=i%8; const FVector2D Min(OX+(12+Column*158)*S,OY+(578+Row*64)*S), Max=Min+FVector2D(150*S,54*S);
        Buttons.Add({FName(Actions[i]),FString(Actions[i]),FBox2D(Min,Max)});
        DrawRect(i==9?FLinearColor(.12,.35,.2):FLinearColor(.13,.19,.17),Min.X,Min.Y,Max.X-Min.X,Max.Y-Min.Y);
        Text(Actions[i],20+Column*158,592+Row*64);
    }
}
bool ACastleHUD::HandlePress(FVector2D P)
{
    for(const auto& B:Buttons) if(B.Rect.IsInsideOrOn(P))
    { if(auto* PC=Cast<ACastleController>(PlayerOwner)) PC->Action(B.Action); return true; }
    // Do not allow clicks on opaque HUD panels to select invisible ground behind them.
    if(Canvas)
    {
        const float S=FMath::Min(Canvas->SizeX/1280.f,Canvas->SizeY/720.f), OY=(Canvas->SizeY-720*S)*.5f;
        if(P.Y<OY+100*S || P.Y>=OY+496*S) return true;
    }
    return false;
}
