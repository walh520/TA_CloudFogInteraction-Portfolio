#pragma once
#include "CoreMinimal.h"

/** SI velocities; double world transforms/time until the render-domain conversion. */
struct FTAFogMotion
{
	uint64 Id=0, Revision=0;
	uint64 FirstRevision=0; // earliest revision coalesced into this same-time interval
	double Begin=0, End=0;
	FTransform Previous=FTransform::Identity, Current=FTransform::Identity;
	FVector SizeCm=FVector(75), LinearMps=FVector::ZeroVector, AngularRadps=FVector::ZeroVector;
	uint32 Shape=0;
	int32 Priority=0;
	float Drag=4, BandCm=50, Wake=1, WakeRadiusCm=100, WakeLife=1.5f;
	bool Solid=true, Discontinuity=true;
};
// Eight float4s, mirrored in TAFogInteraction.ush. No UObject enters the renderer.
struct FTAFogBodyGPU { FVector4f Data[8]; };
struct FTAFogSourcePacket { uint64 Id=0; TArray<FTAFogMotion> Motion; };
class UWorld;
void TAGatherFogInteractions(UWorld* World,const FBox& Bounds,TMap<uint64,uint64>& Revisions,TArray<FTAFogSourcePacket>& Out,int32& Dropped);
