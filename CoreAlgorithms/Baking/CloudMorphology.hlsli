// Function-level project excerpt adapted to explicit inputs. See ../SOURCE_MAP.md.
#ifndef TA_CORE_MORPHOLOGY
#define TA_CORE_MORPHOLOGY
float4 TACloudBuildProfile(float Height, float Type)
{
	const float Stratus = smoothstep(0.0f, 0.12f, Height)
		* (1.0f - smoothstep(0.55f, 0.82f, Height));
	const float Cumulus = pow(smoothstep(0.0f, 0.18f, Height), 1.2f)
		* pow(1.0f - smoothstep(0.68f, 1.0f, Height), 0.75f);
	const float Storm = pow(smoothstep(0.0f, 0.10f, Height), 0.8f)
		* pow(1.0f - smoothstep(0.82f, 1.0f, Height), 0.45f);
	const float Density = Type < 0.5f
		? lerp(Stratus, Cumulus, Type * 2.0f)
		: lerp(Cumulus, Storm, (Type - 0.5f) * 2.0f);

	// Morphology grammar: stratus stays restrained, cumulus grows larger upper
	// billows with a broken base, and storm reserves A for its upper anvil mask.
	float CumulusBillow = lerp(0.20f, 0.45f, smoothstep(0.08f, 0.38f, Height));
	CumulusBillow = lerp(CumulusBillow, 0.80f, smoothstep(0.45f, 0.78f, Height));
	CumulusBillow = lerp(CumulusBillow, 0.40f, smoothstep(0.84f, 1.0f, Height));
	float CumulusErosion = lerp(0.80f, 0.20f, smoothstep(0.08f, 0.32f, Height));
	CumulusErosion = lerp(CumulusErosion, 0.35f, smoothstep(0.55f, 0.82f, Height));
	CumulusErosion = lerp(CumulusErosion, 0.25f, smoothstep(0.90f, 1.0f, Height));

	const float StratusBillow = lerp(0.16f, 0.28f, smoothstep(0.08f, 0.55f, Height));
	const float StratusErosion = lerp(0.55f, 0.22f, smoothstep(0.06f, 0.30f, Height));
	const float StormBillow = lerp(CumulusBillow, 0.72f, smoothstep(0.52f, 0.88f, Height));
	const float StormErosion = lerp(CumulusErosion, 0.30f, smoothstep(0.60f, 0.92f, Height));
	const float StormSpecial = smoothstep(0.70f, 0.86f, Height)
		* (1.0f - smoothstep(0.97f, 1.0f, Height));

	const float Billow = Type < 0.5f
		? lerp(StratusBillow, CumulusBillow, Type * 2.0f)
		: lerp(CumulusBillow, StormBillow, (Type - 0.5f) * 2.0f);
	const float Erosion = Type < 0.5f
		? lerp(StratusErosion, CumulusErosion, Type * 2.0f)
		: lerp(CumulusErosion, StormErosion, (Type - 0.5f) * 2.0f);
	const float Special = StormSpecial * smoothstep(0.50f, 1.0f, Type);
	return saturate(float4(Density, Billow, Erosion, Special));
}
float TACloudDensityRemap(float Value, float Threshold, float Softness)
{
	const float SafeSoftness = max(Softness, 1.0e-4f);
	return smoothstep(Threshold - SafeSoftness, Threshold + SafeSoftness, saturate(Value));
}
float TACloudDensityBaseFromCombinedField(float RawWeather, float RawMacro, float HeightProfile, float CoverageThreshold, float CoverageSoftness, float MacroThreshold, float MacroSoftness)
{
	const float Coverage = TACloudDensityRemap(
		RawWeather,
		CoverageThreshold,
		CoverageSoftness);
	// Coverage moves one Macro isosurface instead of multiplying/remapping a
	// thresholded noise soup. At zero Coverage the lower smoothstep edge is 1,
	// so even a saturated R8 Macro value cannot create cloud in clear weather.
	const float EmptyThreshold = 1.0f + MacroSoftness;
	const float EffectiveThreshold = lerp(
		EmptyThreshold,
		MacroThreshold,
		Coverage);
	const float MacroIsosurface = smoothstep(
		EffectiveThreshold - MacroSoftness,
		EffectiveThreshold + MacroSoftness,
		saturate(RawMacro));
	return saturate(HeightProfile) * MacroIsosurface;
}

float TACloudDensityBaseFromFields(float RawWeather, float2 MacroMorphology, float4 ProfileMorphology, float CoverageThreshold, float CoverageSoftness, float MacroThreshold, float MacroSoftness)
{
	// Macro.R is the connected Perlin scaffold. Macro.G is a calibrated positive
	// dilation offset; Profile.G can only reduce it, so R+G remains conservative.
	const float RawMacro = saturate(MacroMorphology.r
		+ MacroMorphology.g * saturate(ProfileMorphology.g));
	return TACloudDensityBaseFromCombinedField(RawWeather, RawMacro, ProfileMorphology.r, CoverageThreshold, CoverageSoftness, MacroThreshold, MacroSoftness);
}
float4 TACloudBuildSemanticWeather(float Coverage, float TypeNoise, float StormPotential, float Lifecycle, float CloudTypeBase, float CloudTypeVariation, float CoverageCorrelation, float StormStart, float StormFull, float StormBias, float StormVariation)
{
	// Coverage is the governing state. The remaining channels are deliberately
	// derived from it and from lower-frequency fields rather than four unrelated
	// full-band fBms.
	const float CloudType = saturate(
		CloudTypeBase
		+ TypeNoise * CloudTypeVariation
		+ (Coverage - 0.5f) * CoverageCorrelation);
	const float StormGate = smoothstep(
		StormStart,
		StormFull,
		Coverage);
	const float Storm = StormGate * saturate(
		StormBias + StormPotential * StormVariation);
	return float4(Coverage, CloudType, Storm, Lifecycle);
}
#endif
