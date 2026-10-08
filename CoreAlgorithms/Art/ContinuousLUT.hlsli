// Function-level project excerpt adapted to explicit inputs. See ../SOURCE_MAP.md.
#ifndef TA_CORE_CONTINUOUS_LUT
#define TA_CORE_CONTINUOUS_LUT
struct TACloudLUTCoordinates { float2 UV0; float2 UV1; float SliceAlpha; };
TACloudLUTCoordinates TACloudContinuousBaseColorLUTCoordinates(uint TextureWidth, uint TextureHeight, uint RequestedSlices,
	float LuminanceCoordinate,
	float VerticalCoordinate,
	float SliceCoordinate)
{
	const uint SafeWidth = max(TextureWidth, 1u);
	const uint SafeHeight = max(TextureHeight, 1u);
	const uint MaximumSliceCount = max(SafeHeight / 2u, 1u);
	const uint SliceCount = clamp(
		RequestedSlices,
		1u,
		MaximumSliceCount);
	const uint SliceHeightPixels = max(SafeHeight / SliceCount, 1u);
	const float U = (0.5f + saturate(LuminanceCoordinate) * float(SafeWidth - 1u))
		/ float(SafeWidth);
	const float ContinuousSlice = saturate(SliceCoordinate) * float(SliceCount - 1u);
	const uint Slice0 = min(uint(floor(ContinuousSlice)), SliceCount - 1u);
	const uint Slice1 = min(Slice0 + 1u, SliceCount - 1u);
	const float SliceAlpha = frac(ContinuousSlice);
	const float LocalPixelY = 0.5f
		+ saturate(VerticalCoordinate) * float(SliceHeightPixels - 1u);
	const float V0 = (float(Slice0 * SliceHeightPixels) + LocalPixelY)
		/ float(SafeHeight);
	const float V1 = (float(Slice1 * SliceHeightPixels) + LocalPixelY)
		/ float(SafeHeight);
    TACloudLUTCoordinates Result;
    Result.UV0 = float2(U,V0); Result.UV1 = float2(U,V1);
    Result.SliceAlpha = SliceAlpha; return Result;
}
#endif
