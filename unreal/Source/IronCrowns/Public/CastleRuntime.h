#pragma once
#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/HUD.h"
#include "GameFramework/SaveGame.h"
#include "CastleRules.h"
#include "CastleRuntime.generated.h"
class UCameraComponent;
class USpringArmComponent;
class UInstancedStaticMeshComponent;
class UStaticMeshComponent;

UCLASS()
class IRONCROWNS_API UCastleSave : public USaveGame
{
    GENERATED_BODY()
public:
    UPROPERTY(SaveGame) FString Payload;
};

UCLASS()
class IRONCROWNS_API ACastleCamera : public APawn
{
    GENERATED_BODY()
public:
    ACastleCamera();
    UPROPERTY(VisibleAnywhere) TObjectPtr<USpringArmComponent> Arm;
    UPROPERTY(VisibleAnywhere) TObjectPtr<UCameraComponent> Camera;
    void Pan(FVector2D Delta);
    void Zoom(float Amount);
    virtual void Tick(float Dt) override;
};

UCLASS()
class IRONCROWNS_API ACastleController : public APlayerController
{
    GENERATED_BODY()
public:
    ACastleController();
    Castle::Rules Rules;
    Castle::Kind Chosen=Castle::Kind::Stockpile;
    Castle::Cell Plot;
    bool bHasPlot=false;
    FString Notice=TEXT("Unreal migration prototype: select a building, Suggest plot, then Build. Combat is not ported.");
    void Action(FName Name);
    void ScreenAction(FVector2D Point);
    virtual void BeginPlay() override;
    virtual void SetupInputComponent() override;
    virtual void PlayerTick(float Dt) override;
    static FVector Position(Castle::Cell Cell);
private:
    UPROPERTY() TObjectPtr<AActor> Terrain;
    UPROPERTY() TObjectPtr<UStaticMeshComponent> Ghost;
    UPROPERTY() TMap<int32,TObjectPtr<AActor>> BuildingActors;
    bool bMouseHeld=false, bDragging=false;
    FVector2D PointerStart, LastPointer;
    TMap<int32,FVector2D> Fingers;
    float Pinch=0;
    double MapConfirmationUntil=0;
    bool bNeedsRebuild=false;
    void Rebuild();
    void RefreshBuildings();
    void MouseDown();
    void MouseUp();
    void Wheel(float Value);
    void TouchDown(ETouchIndex::Type Finger,FVector Location);
    void TouchMove(ETouchIndex::Type Finger,FVector Location);
    void TouchUp(ETouchIndex::Type Finger,FVector Location);
    bool Save();
    bool Load();
};

UCLASS()
class IRONCROWNS_API ACastleHUD : public AHUD
{
    GENERATED_BODY()
public:
    virtual void DrawHUD() override;
    bool HandlePress(FVector2D Point);
private:
    struct FButton { FName Action; FString Text; FBox2D Rect; };
    TArray<FButton> Buttons;
};

UCLASS()
class IRONCROWNS_API ACastleMode : public AGameModeBase
{
    GENERATED_BODY()
public:
    ACastleMode();
    virtual void BeginPlay() override;
};
