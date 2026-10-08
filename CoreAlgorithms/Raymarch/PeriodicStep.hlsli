// Function-level project excerpt adapted to explicit inputs. See ../SOURCE_MAP.md.
#ifndef TA_CORE_PERIODIC_STEP
#define TA_CORE_PERIODIC_STEP
float TACloudDensityFootprintLod(float StepCm, float MinimumVoxelCm)
{
	return max(0.0f, log2(max(StepCm, 1.0f) / max(MinimumVoxelCm, 1.0f)));
}
float TACloudDistanceToPeriodicCellBoundary(
	float3 CoordinatesCm,
	float3 Direction,
	float3 PeriodCm,
	float3 BaseDimensions,
	uint Mip,
	uint DimensionCount)
{
	const float3 CellCount = max(1.0f, floor(BaseDimensions / exp2((float)Mip)));
	const float3 CellCoordinates = frac(CoordinatesCm / max(PeriodCm, 1.0f)) * CellCount;
	const float3 CellDirectionPerCm = Direction / max(PeriodCm, 1.0f) * CellCount;
	float Result = 1.0e30f;
	[unroll]
	for (uint Axis = 0u; Axis < 3u; ++Axis)
	{
		if (Axis >= DimensionCount)
		{
			continue;
		}
		const float AxisDirection = CellDirectionPerCm[Axis];
		if (abs(AxisDirection) > 1.0e-8f)
		{
			const float FractionInCell = frac(CellCoordinates[Axis]);
			const float CellsToBoundary = AxisDirection > 0.0f
				? max(1.0e-4f, 1.0f - FractionInCell)
				: max(1.0e-4f, FractionInCell);
			Result = min(Result, CellsToBoundary / abs(AxisDirection));
		}
	}
	return Result;
}
#endif
