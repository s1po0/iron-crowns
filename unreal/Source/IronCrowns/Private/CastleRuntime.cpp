#include "CastleRuntime.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "Components/InstancedStaticMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/TextRenderComponent.h"
#include "Components/DirectionalLightComponent.h"
#include "Components/SkyLightComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/SkyLight.h"
#include "Engine/Canvas.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Kismet/GameplayStatics.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"
#include "Dom/JsonObject.h"

namespace
{
bool MousePosition(APlayerController* PC,FVector2D& Out)
{
    float X,Y; if(!PC->GetMousePosition(X,Y)) return false; Out=FVector2D(X,Y); return true;
}
UStaticMesh* Cube() { return LoadObject<UStaticMesh>(nullptr,TEXT("/Engine/BasicShapes/Cube.Cube")); }
UMaterialInstanceDynamic* ColorMaterial(UObject* Owner,FLinearColor Color)
{
    auto* Base=LoadObject<UMaterialInterface>(nullptr,TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
    if(!Base) return nullptr;
    auto* M=UMaterialInstanceDynamic::Create(Base,Owner); M->SetVectorParameterValue(TEXT("Color"),Color); return M;
}
UStaticMeshComponent* Box(AActor* Owner,FVector Local,FVector Scale,FLinearColor Color)
{
    auto* C=NewObject<UStaticMeshComponent>(Owner);
    C->SetMobility(EComponentMobility::Movable); C->SetStaticMesh(Cube()); C->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Owner->AddInstanceComponent(C); C->SetupAttachment(Owner->GetRootComponent()); C->RegisterComponent();
    C->SetRelativeLocation(Local); C->SetRelativeScale3D(Scale); C->SetMaterial(0,ColorMaterial(Owner,Color)); return C;
}
AActor* EmptyActor(UWorld* World)
{
    auto* A=World->SpawnActor<AActor>();
    auto* Root=NewObject<USceneComponent>(A); A->AddInstanceComponent(Root); A->SetRootComponent(Root); Root->RegisterComponent(); return A;
}
}
ACastleCamera::ACastleCamera()
{
    PrimaryActorTick.bCanEverTick=true;
    SetRootComponent(CreateDefaultSubobject<USceneComponent>(TEXT("Root")));
    Arm=CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraArm")); Arm->SetupAttachment(RootComponent);
    Arm->TargetArmLength=7000; Arm->bDoCollisionTest=false; Arm->SetRelativeRotation(FRotator(-55,-45,0));
    Camera=CreateDefaultSubobject<UCameraComponent>(TEXT("Camera")); Camera->SetupAttachment(Arm); Camera->FieldOfView=45;
}
void ACastleCamera::Zoom(float Amount) { Arm->TargetArmLength=FMath::Clamp(Arm->TargetArmLength+Amount,1800.f,12000.f); }
void ACastleCamera::Pan(FVector2D D)
{
    FVector Right=Camera->GetRightVector(), Forward=Camera->GetUpVector(); Right.Z=0; Forward.Z=0;
    FVector P=GetActorLocation()-Right.GetSafeNormal()*D.X*Arm->TargetArmLength*.0015f+Forward.GetSafeNormal()*D.Y*Arm->TargetArmLength*.0015f;
    P.X=FMath::Clamp(P.X,-5100.f,5100.f); P.Y=FMath::Clamp(P.Y,-5100.f,5100.f); P.Z=0; SetActorLocation(P);
}
void ACastleCamera::Tick(float Dt)
{
    Super::Tick(Dt);
    if(auto* PC=Cast<APlayerController>(GetController()))
        Pan(FVector2D(-PC->GetInputAxisValue(TEXT("PanRight")),PC->GetInputAxisValue(TEXT("PanForward")))*Dt*500);
}
ACastleController::ACastleController() { bShowMouseCursor=true; PrimaryActorTick.bCanEverTick=true; }
FVector ACastleController::Position(Castle::Cell C) { return FVector((C.x-20)*Castle::Tile,(C.y-20)*Castle::Tile,0); }
void ACastleController::BeginPlay()
{
    Super::BeginPlay(); SetInputMode(FInputModeGameOnly());
    if(HasAuthority() && !GetPawn()) Possess(GetWorld()->SpawnActor<ACastleCamera>());
    Rebuild();
}
void ACastleController::SetupInputComponent()
{
    Super::SetupInputComponent();
    InputComponent->BindAction(TEXT("Select"),IE_Pressed,this,&ACastleController::MouseDown);
    InputComponent->BindAction(TEXT("Select"),IE_Released,this,&ACastleController::MouseUp);
    InputComponent->BindAxis(TEXT("Zoom"),this,&ACastleController::Wheel);
    InputComponent->BindAxis(TEXT("PanRight")); InputComponent->BindAxis(TEXT("PanForward"));
    InputComponent->BindTouch(IE_Pressed,this,&ACastleController::TouchDown);
    InputComponent->BindTouch(IE_Repeat,this,&ACastleController::TouchMove);
    InputComponent->BindTouch(IE_Released,this,&ACastleController::TouchUp);
}
void ACastleController::MouseDown()
{
    if(MousePosition(this,PointerStart)) { bMouseHeld=true; bDragging=false; LastPointer=PointerStart; }
}
void ACastleController::MouseUp()
{
    if(bMouseHeld && !bDragging) ScreenAction(LastPointer); bMouseHeld=false;
}
void ACastleController::Wheel(float Value) { if(auto* C=Cast<ACastleCamera>(GetPawn())) C->Zoom(-Value*400); }
void ACastleController::TouchDown(ETouchIndex::Type F,FVector P)
{
    Fingers.Add(int32(F),FVector2D(P.X,P.Y));
    if(Fingers.Num()==1) { PointerStart=LastPointer=FVector2D(P.X,P.Y); bDragging=false; }
    if(Fingers.Num()==2) { TArray<FVector2D> V; Fingers.GenerateValueArray(V); Pinch=FVector2D::Distance(V[0],V[1]); bDragging=true; }
}
void ACastleController::TouchMove(ETouchIndex::Type F,FVector P)
{
    const FVector2D Now(P.X,P.Y); if(!Fingers.Contains(int32(F))) return; Fingers[int32(F)]=Now;
    if(auto* C=Cast<ACastleCamera>(GetPawn()))
    {
        if(Fingers.Num()==2) { TArray<FVector2D> V; Fingers.GenerateValueArray(V); float Span=FVector2D::Distance(V[0],V[1]); C->Zoom((Pinch-Span)*12); Pinch=Span; }
        else { bDragging|=FVector2D::Distance(Now,PointerStart)>12; if(bDragging) C->Pan(Now-LastPointer); }
    }
    LastPointer=Now;
}
void ACastleController::TouchUp(ETouchIndex::Type F,FVector P)
{
    if(!Fingers.Contains(int32(F))) return;
    if(Fingers.Num()==1 && !bDragging) ScreenAction(FVector2D(P.X,P.Y)); Fingers.Remove(int32(F));
}
void ACastleController::ScreenAction(FVector2D P)
{
    if(auto* H=Cast<ACastleHUD>(GetHUD())) if(H->HandlePress(P)) return;
    FVector Origin,Direction;
    if(DeprojectScreenPositionToWorld(P.X,P.Y,Origin,Direction) && Direction.Z<-.001f)
    {
        const FVector Hit=Origin+Direction*(-Origin.Z/Direction.Z);
        Plot={FMath::RoundToInt(Hit.X/Castle::Tile+20),FMath::RoundToInt(Hit.Y/Castle::Tile+20)};
        bHasPlot=true; const auto Error=Rules.BuildError(Chosen,Plot);
        Notice=Error.empty()? TEXT("Plot selected. Press Build to confirm.") : UTF8_TO_TCHAR(Error.c_str());
    }
}
void ACastleController::Action(FName N)
{
    for(int i=1;i<int(Castle::Kind::Count);++i) if(N==FName(UTF8_TO_TCHAR(Castle::Name(Castle::Kind(i)))))
    { Chosen=Castle::Kind(i); bHasPlot=false; Notice=TEXT("Tap empty ground, or Suggest plot. Then press Build."); return; }
    if(N==TEXT("Build"))
    {
        if(!bHasPlot) { Notice=TEXT("Choose a plot first (tap ground or Suggest plot)."); return; }
        const auto Error=Rules.BuildError(Chosen,Plot);
        if(!Error.empty()) { Notice=UTF8_TO_TCHAR(Error.c_str()); return; }
        if(Rules.Place(Chosen,Plot)) { bHasPlot=false; Notice=TEXT("Construction started: eight simulation seconds."); RefreshBuildings(); }
    }
    else if(N==TEXT("Suggest"))
    {
        Castle::Cell Center{19,19}; if(GetPawn()) { const FVector P=GetPawn()->GetActorLocation(); Center={FMath::RoundToInt(P.X/300+20),FMath::RoundToInt(P.Y/300+20)}; }
        if(Rules.Suggest(Chosen,Center,Plot)) { bHasPlot=true; Notice=TEXT("Suitable plot selected. Press Build."); if(GetPawn()) GetPawn()->SetActorLocation(Position(Plot)); }
        else Notice=TEXT("No affordable, unoccupied plot is available.");
    }
    else if(N==TEXT("Toggle gate")) { Notice=Rules.ToggleGate(Plot)?TEXT("Gate toggled."):TEXT("Select a completed gate on the map first."); bNeedsRebuild=true; }
    else if(N==TEXT("Save")) Notice=Save()?TEXT("Unreal save stored; previous slot backed up."):TEXT("Save failed. Existing save was not deliberately removed.");
    else if(N==TEXT("Load")) Notice=Load()?TEXT("Unreal save restored."):TEXT("No valid Unreal save. Godot saves are separate.");
    else if(N==TEXT("Next map"))
    {
        const double Now=FPlatformTime::Seconds();
        if(MapConfirmationUntil<Now) { MapConfirmationUntil=Now+5; Notice=TEXT("Unsaved progress will be lost. Tap Next map again within five seconds, or Save first."); }
        else { Rules.Reset((Rules.state.mission+1)%3); bNeedsRebuild=true; bHasPlot=false; MapConfirmationUntil=0; Notice=TEXT("New map. Start with stockpile, woodcutter and farm."); }
    }
}
void ACastleController::PlayerTick(float Dt)
{
    Super::PlayerTick(Dt);
    if(bNeedsRebuild) { bNeedsRebuild=false; Rebuild(); }
    if(bMouseHeld) { FVector2D P; if(MousePosition(this,P)) { bDragging|=FVector2D::Distance(P,PointerStart)>12; if(bDragging) if(auto* C=Cast<ACastleCamera>(GetPawn())) C->Pan(P-LastPointer); LastPointer=P; } }
    Rules.Step(Dt); RefreshBuildings();
    if(Ghost)
    {
        Ghost->SetVisibility(bHasPlot);
        const float N=Castle::Footprint(Chosen); Ghost->SetWorldLocation(Position(Plot)+FVector((N-1)*150,(N-1)*150,6));
        Ghost->SetWorldScale3D(FVector(N*3,N*3,.12));
    }
}
void ACastleController::Rebuild()
{
    for(auto& Pair:BuildingActors) if(IsValid(Pair.Value.Get())) Pair.Value->Destroy(); BuildingActors.Empty();
    if(Terrain) Terrain->Destroy(); Terrain=EmptyActor(GetWorld());
    UInstancedStaticMeshComponent* Tiles[2];
    for(int i=0;i<2;++i)
    {
        Tiles[i]=NewObject<UInstancedStaticMeshComponent>(Terrain.Get()); Terrain->AddInstanceComponent(Tiles[i]);
        Tiles[i]->SetupAttachment(Terrain->GetRootComponent()); Tiles[i]->SetStaticMesh(Cube()); Tiles[i]->SetCollisionEnabled(ECollisionEnabled::NoCollision);
        Tiles[i]->SetMaterial(0,ColorMaterial(Terrain.Get(),i?FLinearColor(.12,.3,.4):FLinearColor(.3,.38,.19)));
        Tiles[i]->RegisterComponent();
    }
    for(int y=0;y<40;++y) for(int x=0;x<40;++x)
    {
        const bool Wet=Castle::Water({x,y},Rules.state.mission);
        Tiles[Wet?1:0]->AddInstance(FTransform(FQuat::Identity,Position({x,y})+FVector(0,0,Wet?-25:-10),FVector(3,3,.2)));
    }
    Ghost=Box(Terrain.Get(),FVector::ZeroVector,FVector(6,6,.12),FLinearColor(.8,.65,.2)); Ghost->SetVisibility(false);
    RefreshBuildings();
}
void ACastleController::RefreshBuildings()
{
    for(const auto& B:Rules.state.buildings)
    {
        AActor* A=BuildingActors.FindRef(B.id).Get();
        if(!IsValid(A))
        {
            A=EmptyActor(GetWorld()); BuildingActors.Add(B.id,A); const float N=Castle::Footprint(B.kind);
            A->SetActorLocation(Position(B.cell)+FVector((N-1)*150,(N-1)*150,0));
            const bool Flat=B.kind==Castle::Kind::Farm || B.kind==Castle::Kind::Stockpile;
            const float Height=Flat?35: B.kind==Castle::Kind::Keep?650:300;
            if(B.kind==Castle::Kind::Gate)
            {
                Box(A,FVector(-110,0,150),FVector(.6,1,3),FLinearColor(.45,.43,.37));
                Box(A,FVector(110,0,150),FVector(.6,1,3),FLinearColor(.45,.43,.37));
                Box(A,FVector(0,0,310),FVector(2.8,1,.4),FLinearColor(.45,.43,.37));
                if(!B.open) Box(A,FVector(0,0,140),FVector(1.6,.3,2.8),FLinearColor(.25,.15,.07));
            }
            else Box(A,FVector(0,0,Height*.5),FVector(N*2.7,N*2.7,Height/100),Flat?FLinearColor(.5,.36,.14):FLinearColor(.45,.43,.37));
            if(B.kind==Castle::Kind::Farm) for(int Row=0;Row<7;++Row)
                Box(A,FVector(0,-330+Row*110,55),FVector(7,.14,.45),FLinearColor(.65,.56,.23));
            if(B.kind==Castle::Kind::Keep) for(int X:{-1,1}) for(int Y:{-1,1})
                Box(A,FVector(X*330,Y*330,400),FVector(1.6,1.6,8),FLinearColor(.52,.5,.45));
            auto* Text=NewObject<UTextRenderComponent>(A); A->AddInstanceComponent(Text); Text->SetupAttachment(A->GetRootComponent()); Text->RegisterComponent();
            Text->SetText(FText::FromString(UTF8_TO_TCHAR(Castle::Name(B.kind)))); Text->SetWorldSize(90); Text->SetRelativeLocation(FVector(0,0,Height+120)); Text->SetRelativeRotation(FRotator(55,135,0));
        }
        A->SetActorScale3D(FVector(1,1,.15+.85*B.construction/8));
    }
}
ACastleMode::ACastleMode() { DefaultPawnClass=ACastleCamera::StaticClass(); PlayerControllerClass=ACastleController::StaticClass(); HUDClass=ACastleHUD::StaticClass(); }
void ACastleMode::BeginPlay()
{
    Super::BeginPlay();
    auto* Sun=GetWorld()->SpawnActor<ADirectionalLight>(); Sun->SetActorRotation(FRotator(-50,-35,0)); Sun->GetLightComponent()->SetIntensity(3);
    auto* Sky=GetWorld()->SpawnActor<ASkyLight>(); Sky->GetLightComponent()->SetIntensity(.8f);
}
