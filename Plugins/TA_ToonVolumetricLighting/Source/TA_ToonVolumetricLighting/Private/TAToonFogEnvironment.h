#pragma once
#include "CoreMinimal.h"
#include "TAToonFogInteraction.h"

struct FTAFogTerrainSnapshot
{
	uint64 Generation=0;
	FIntPoint Size=FIntPoint(0,0);
	// Domain-local height in metres, coverage validity. Includes one XY halo cell.
	TArray<FVector2f> Samples;
};
struct FTAFogEnvironment
{
	uint32 Flags=0; // wind, buoyancy, vorticity, ground source, decay, activity
	FVector4f Wind=FVector4f(.3f,4,.1f,2);
	FVector4f Cooling=FVector4f(.06f,1,6,20);
	FVector4f Dynamics=FVector4f(.2f,.4f,.5f,0); // N, gamma, max extra du, turn radians
	FVector4f Sources=FVector4f(.5f,25,60,1.5f);
	FVector4f Detail=FVector4f(0,.5f,4,0); // amplitude, scale, period, simulation time
};
struct FTAFogEffectRecord
{
	FTAFogMotion Motion;
	FVector4f Source=FVector4f(1,25,.25f,2.5f); // target, restore, feather m, structure m
	FVector4f Roll=FVector4f(1.5f,3,.5f,2); // radius, half length, angular speed, response
	float Life=6;
	uint64 Trigger=0;
	bool SourceEnabled=true,RollEnabled=false,Loop=false;
};
struct FTAFogEffectPacket { uint64 Id=0; TArray<FTAFogEffectRecord> Records; };
void TAGatherFogEffects(UWorld* World,const FBox& Bounds,TMap<uint64,uint64>& Revisions,TArray<FTAFogEffectPacket>& Out,int32& Dropped);
