#include "CastleRuntime.h"
#include "Kismet/GameplayStatics.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"
#include "Dom/JsonObject.h"
namespace
{
const FString Slot=TEXT("IronCrownsUnreal_v1");
bool Integer(const TSharedPtr<FJsonObject>& O,const TCHAR* Key,int& Result)
{
    double V; if(!O.IsValid() || !O->TryGetNumberField(Key,V) || !FMath::IsFinite(V) || V<-1000000 || V>1000000 || V!=FMath::FloorToDouble(V)) return false;
    Result=static_cast<int>(V); return true;
}
}
bool ACastleController::Save()
{
    if(!Castle::Rules::Validate(Rules.state)) return false;
    auto Root=MakeShared<FJsonObject>(); const auto& S=Rules.state;
    Root->SetNumberField(TEXT("schema"),1); Root->SetNumberField(TEXT("mission"),S.mission); Root->SetNumberField(TEXT("nextId"),S.nextId);
    const auto& R=S.resources;
    Root->SetNumberField(TEXT("wood"),R.wood); Root->SetNumberField(TEXT("stone"),R.stone); Root->SetNumberField(TEXT("grain"),R.grain);
    Root->SetNumberField(TEXT("flour"),R.flour); Root->SetNumberField(TEXT("bread"),R.bread); Root->SetNumberField(TEXT("gold"),R.gold);
    TArray<TSharedPtr<FJsonValue>> Items;
    for(const auto& B:S.buildings)
    {
        auto O=MakeShared<FJsonObject>(); O->SetNumberField(TEXT("id"),B.id); O->SetNumberField(TEXT("kind"),int(B.kind));
        O->SetNumberField(TEXT("x"),B.cell.x); O->SetNumberField(TEXT("y"),B.cell.y);
        O->SetNumberField(TEXT("construction"),B.construction); O->SetNumberField(TEXT("clock"),B.clock); O->SetBoolField(TEXT("open"),B.open);
        Items.Add(MakeShared<FJsonValueObject>(O));
    }
    Root->SetArrayField(TEXT("buildings"),Items);
    auto* Save=Cast<UCastleSave>(UGameplayStatics::CreateSaveGameObject(UCastleSave::StaticClass()));
    if(!Save || !FJsonSerializer::Serialize(Root,TJsonWriterFactory<>::Create(&Save->Payload))) return false;
    if(UGameplayStatics::DoesSaveGameExist(Slot,0))
    {
        auto* Previous=UGameplayStatics::LoadGameFromSlot(Slot,0);
        if(!Previous || !UGameplayStatics::SaveGameToSlot(Previous,Slot+TEXT("_previous"),0)) return false;
    }
    return UGameplayStatics::SaveGameToSlot(Save,Slot,0);
}
bool ACastleController::Load()
{
    auto* Save=Cast<UCastleSave>(UGameplayStatics::LoadGameFromSlot(Slot,0));
    if(!Save || Save->Payload.Len()>262144) return false;
    TSharedPtr<FJsonObject> Root;
    if(!FJsonSerializer::Deserialize(TJsonReaderFactory<>::Create(Save->Payload),Root) || !Root.IsValid()) return false;
    Castle::State S; auto& R=S.resources;
    if(!Integer(Root,TEXT("schema"),S.schema) || !Integer(Root,TEXT("mission"),S.mission) || !Integer(Root,TEXT("nextId"),S.nextId)
       || !Integer(Root,TEXT("wood"),R.wood) || !Integer(Root,TEXT("stone"),R.stone) || !Integer(Root,TEXT("grain"),R.grain)
       || !Integer(Root,TEXT("flour"),R.flour) || !Integer(Root,TEXT("bread"),R.bread) || !Integer(Root,TEXT("gold"),R.gold)) return false;
    const TArray<TSharedPtr<FJsonValue>>* Items=nullptr;
    if(!Root->TryGetArrayField(TEXT("buildings"),Items) || !Items || Items->Num()>256) return false;
    for(const auto& V:*Items)
    {
        const TSharedPtr<FJsonObject>* O=nullptr; if(!V.IsValid() || !V->TryGetObject(O) || !O || !O->IsValid()) return false;
        Castle::Building B; int Kind; double Construction,Clock;
        if(!Integer(*O,TEXT("id"),B.id) || !Integer(*O,TEXT("kind"),Kind) || !Integer(*O,TEXT("x"),B.cell.x) || !Integer(*O,TEXT("y"),B.cell.y)
           || !(*O)->TryGetNumberField(TEXT("construction"),Construction) || !(*O)->TryGetNumberField(TEXT("clock"),Clock) || !(*O)->TryGetBoolField(TEXT("open"),B.open)) return false;
        if(!FMath::IsFinite(Construction) || !FMath::IsFinite(Clock) || Construction<0 || Construction>8 || Clock<0 || Clock>=12) return false;
        B.kind=Castle::Kind(Kind); B.construction=float(Construction); B.clock=float(Clock); S.buildings.push_back(B);
    }
    if(!Rules.Restore(S)) return false;
    bHasPlot=false; bNeedsRebuild=true; return true;
}
