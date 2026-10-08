// Function-level project excerpt adapted to explicit inputs. See ../SOURCE_MAP.md.
// LUT color is supplied by the caller at the documented coordinates.
// Rec.709 luminance helper and explicit structs are extraction adapters.
#ifndef TA_CORE_CLOUD_ART
#define TA_CORE_CLOUD_ART
#define TA_CLOUD_ART_FEATURE_WRAP (1u << 0u)
#define TA_CLOUD_ART_FEATURE_DARK_EDGE (1u << 1u)
#define TA_CLOUD_ART_FEATURE_SILVER (1u << 2u)
#define TA_CLOUD_ART_FEATURE_POWDER (1u << 3u)
#define TA_CLOUD_ART_FEATURE_CURVATURE (1u << 4u)
#define TA_CLOUD_ART_FEATURE_INNER_GLOW (1u << 5u)
#define TA_CLOUD_ART_FEATURE_WEATHER (1u << 6u)
#define TA_CLOUD_ART_FEATURE_DISTANCE (1u << 7u)
struct TACloudArtParameters
{
    float3 BodyColor;
    uint ColorLUTColorMode;
    uint ColorLUTSliceAxis;
    float ColorLUTStrength;
    uint ColorLUTVerticalAxis;
    float ConcaveDarkening;
    float ConcaveTintStrength;
    float ConvexLift;
    float ConvexSaturation;
    float CurvatureStrength;
    float CurvatureThresholdMax;
    float CurvatureThresholdMin;
    float DarkEdgeExponent;
    float DarkEdgeOpticalDensity;
    float DarkEdgeStrength;
    float DistanceFadeEndKm;
    float DistanceFadeStartKm;
    float DistanceResponseStrength;
    float DistantArtStrength;
    float EnergyLimit;
    float GradientScale;
    float3 InnerGlowColor;
    float InnerGlowStrength;
    float InnerLightAbsorption;
    float InnerViewDensity;
    float LuminanceScale;
    float OpticalDepthScale;
    float PhysicalContribution;
    float PowderDensity;
    float PowderStrength;
    float3 ShadowColor;
    float3 SilverColor;
    float SilverExponent;
    float SilverOpticalDensity;
    float SilverStrength;
    float3 StormColor;
    float StormDarkening;
    float StormFeatureBoost;
    float Strength;
    float3 SunlitColor;
    float TypeColorStrength;
    uint UseColorLUT;
    float Wrap;
    uint FeatureMask;
};
struct TACloudArtInputs
{
    float BoundaryGradient;
    float CavityProbability;
    float CloudType;
    float Coverage;
    float3 DirectPremultiplied;
    float Lifecycle;
    float MuForward;
    float NDotL;
    float NormalizedHeight;
    float3 PhysicalColor;
    float PhysicalLuminance;
    float3 PhysicalPremultiplied;
    float3 SampledLUTBaseColor;
    float SignedCurvature;
    float Storm;
    float TauEdge;
    float TauLight;
    float TauLocal;
    float ViewOpticalDepth;
    float DepthKm;
};
float TACloudLuminance(float3 Color) { return dot(Color, float3(0.2126, 0.7152, 0.0722)); }
bool TACloudArtFeatureEnabled(uint Mask, uint FeatureBit) { return (Mask & FeatureBit) != 0u; }
float3 TACloudArtMatchLuminance(float3 ChromaticColor, float TargetLuminance)
{
	const float3 NonNegativeColor = max(ChromaticColor, 0.0f);
	const float SourceLuminance = TACloudLuminance(NonNegativeColor);
	return SourceLuminance > 1.0e-5f && TargetLuminance > 0.0f
		? NonNegativeColor * (TargetLuminance / SourceLuminance)
		: 0.0f;
}

// Structural art can redistribute the already integrated direct-light energy,
// but it cannot manufacture a fixed-color emissive term. The returned value is
// premultiplied by physical coverage because DirectBudgetCP already is.
float3 TACloudArtTintDirectBudget(float3 DirectBudgetCP, float3 ArtTint)
{
	return TACloudArtMatchLuminance(
		ArtTint,
		TACloudLuminance(max(DirectBudgetCP, 0.0f)));
}
float3 TACloudEvaluateContinuousArt(TACloudArtInputs Features, TACloudArtParameters P, bool HasKeyArtLight)
{
    const float DepthKm = Features.DepthKm;
    const float Coverage = Features.Coverage;
	const float3 PhysicalPremultiplied = Features.PhysicalPremultiplied;
	const float3 PhysicalColor = Features.PhysicalColor;
	const float PhysicalLuminance = Features.PhysicalLuminance;
	const float LuminanceResponse = 1.0f - exp(-max(0.0f, PhysicalLuminance) * P.LuminanceScale);
	const float OpticalDepth = Features.ViewOpticalDepth;
	const float OpticalDepthResponse = 1.0f - exp(-OpticalDepth * P.OpticalDepthScale);
	const float BoundaryGradient = saturate(
		Features.BoundaryGradient * P.GradientScale);
	// A8 director contract. These switches and continuous response coordinates
	// affect only the full-resolution art interpretation, never the physical ABI.
	const bool EnableWrap = TACloudArtFeatureEnabled(P.FeatureMask, TA_CLOUD_ART_FEATURE_WRAP);
	const bool EnableDarkEdge = TACloudArtFeatureEnabled(P.FeatureMask, TA_CLOUD_ART_FEATURE_DARK_EDGE);
	const bool EnableSilver = TACloudArtFeatureEnabled(P.FeatureMask, TA_CLOUD_ART_FEATURE_SILVER);
	const bool EnablePowder = TACloudArtFeatureEnabled(P.FeatureMask, TA_CLOUD_ART_FEATURE_POWDER);
	const bool EnableCurvature = TACloudArtFeatureEnabled(P.FeatureMask, TA_CLOUD_ART_FEATURE_CURVATURE);
	const bool EnableInnerGlow = TACloudArtFeatureEnabled(P.FeatureMask, TA_CLOUD_ART_FEATURE_INNER_GLOW);
	const bool EnableWeather = TACloudArtFeatureEnabled(P.FeatureMask, TA_CLOUD_ART_FEATURE_WEATHER);
	const bool EnableDistance = TACloudArtFeatureEnabled(P.FeatureMask, TA_CLOUD_ART_FEATURE_DISTANCE);
	// Cloud type, storm and lifecycle are ray-weighted, temporally reconstructed
	// ABI members. Lifecycle already shaped density and remains diagnostic/LUT
	// data; it is never applied as a second radiance multiplier.
	const float CloudType = Features.CloudType;
	const float Storm = Features.Storm;
	const float Lifecycle = Features.Lifecycle;
	const float PaletteCloudType = EnableWeather ? CloudType : 0.5f;
	const float PaletteStorm = EnableWeather ? Storm : 0.0f;
	const float WeatherFeatureResponse = EnableWeather
		? 1.0f + PaletteStorm * max(P.StormFeatureBoost, 0.0f)
		: 1.0f;
	const float DistanceFadeStartKm = max(P.DistanceFadeStartKm, 0.0f);
	const float DistanceFadeEndKm = max(
		P.DistanceFadeEndKm,
		DistanceFadeStartKm + 1.0e-3f);
	const float RawDistanceFade = smoothstep(
		DistanceFadeStartKm,
		DistanceFadeEndKm,
		max(DepthKm, 0.0f));
	const float DistanceFade = EnableDistance
		? RawDistanceFade * saturate(P.DistanceResponseStrength)
		: 0.0f;
	const float DistanceArtResponse = lerp(
		1.0f,
		saturate(P.DistantArtStrength),
		DistanceFade);
	// A6 consumes the signed world-space curvature proxy from the ABI. Positive
	// and negative lobes are evaluated independently, so they cannot overlap or
	// swap meaning with screen orientation.
	const float SignedCurvature = clamp(Features.SignedCurvature, -1.0f, 1.0f);
	const float CurvatureThresholdMin = clamp(
		P.CurvatureThresholdMin,
		0.0f,
		0.999f);
	const float CurvatureThresholdMax = clamp(
		P.CurvatureThresholdMax,
		CurvatureThresholdMin + 0.001f,
		1.0f);
	const float PositiveCurvature = max(SignedCurvature, 0.0f);
	const float NegativeCurvature = max(-SignedCurvature, 0.0f);
	const float ConvexMask = smoothstep(
		CurvatureThresholdMin,
		CurvatureThresholdMax,
		PositiveCurvature) * BoundaryGradient;
	const float ConcaveMask = smoothstep(
		CurvatureThresholdMin,
		CurvatureThresholdMax,
		NegativeCurvature) * BoundaryGradient;
	const float ConvexAmount = EnableCurvature
		? 1.0f - exp(-max(P.CurvatureStrength, 0.0f)
			* WeatherFeatureResponse * ConvexMask)
		: 0.0f;
	const float ConcaveAmount = EnableCurvature
		? 1.0f - exp(-max(P.CurvatureStrength, 0.0f)
			* WeatherFeatureResponse * ConcaveMask)
		: 0.0f;
	const float NDotL = Features.NDotL;
	// A4: continuous wrap diffuse. With no valid key light, use a neutral
	// palette coordinate and disable the light-directed dark-edge term.
	const float UnwrappedLight = HasKeyArtLight
		? saturate(NDotL)
		: 0.5f;
	const float WrappedLight = HasKeyArtLight
		? saturate((NDotL + P.Wrap) / max(1.0f + P.Wrap, 1.0e-4f))
		: 0.5f;
	const float WrapLight = EnableWrap ? WrappedLight : UnwrappedLight;
	const float MuForward = clamp(Features.MuForward, -1.0f, 1.0f);
	const float ViewLight = saturate(MuForward);
	const float3 DirectColor = Features.DirectPremultiplied
		/ max(Features.Coverage, 1.0e-4f);
	const float DirectLuminance = TACloudLuminance(DirectColor);
	const float KeyLightEnergyResponse = HasKeyArtLight
		? 1.0f - exp(-max(DirectLuminance, 0.0f) * P.LuminanceScale)
		: 0.0f;
	// A5 silver: directional forward-scattering exaggeration using the
	// ray-integrated edge optical depth, never whole-ray view thickness.
	const float SilverAngularResponse = pow(
		ViewLight,
		max(P.SilverExponent, 1.0f));
	const float SilverEdgeOpticalResponse = 1.0f - exp(
		-max(P.SilverOpticalDensity, 0.0f) * Features.TauEdge);
	const float SilverStructuralResponse = SilverAngularResponse
		* SilverEdgeOpticalResponse
		* BoundaryGradient;
	const float Silver = EnableSilver && HasKeyArtLight
		? 1.0f - exp(-max(P.SilverStrength, 0.0f)
			* WeatherFeatureResponse * SilverStructuralResponse)
		: 0.0f;
	const float BacklightResponse = HasKeyArtLight
		? pow(saturate(1.0f - WrapLight), max(P.DarkEdgeExponent, 0.1f))
		: 0.0f;
	const float DarkThicknessResponse = 1.0f
		- exp(-max(P.DarkEdgeOpticalDensity, 0.0f) * OpticalDepth);
	const float RawDarkEdge = EnableDarkEdge
		? max(P.DarkEdgeStrength, 0.0f)
			* WeatherFeatureResponse
			* BacklightResponse
			* BoundaryGradient
			* DarkThicknessResponse
		: 0.0f;
	// Smoothly cap attenuation below one so even deliberately extreme settings
	// cannot collapse a cloud boundary into a pure black contour.
	const float DarkEdge = 0.85f * (1.0f - exp(-RawDarkEdge));
	// A7 bright seams / inner glow. This is the document's continuous response:
	// Pcavity * exp(-kL * TauLight) * (1 - exp(-kV * TauView)). TauLight and
	// TauView come from the ray-integrated Art Feature ABI; DirectShare is not an
	// optical-depth proxy. The already integrated key-light energy is an
	// additional hard gate, so the artistic color cannot become self-emission
	// when the physical direct-light path carries no energy.
	const float InnerCavityProbability = saturate(Features.CavityProbability);
	const float InnerLightTransmittance = HasKeyArtLight
		? exp(-max(P.InnerLightAbsorption, 0.0f) * max(Features.TauLight, 0.0f))
		: 0.0f;
	const float InnerViewOpticalResponse = 1.0f - exp(
		-max(P.InnerViewDensity, 0.0f) * OpticalDepth);
	const float InnerGlowStructuralResponse = InnerCavityProbability
		* InnerLightTransmittance
		* InnerViewOpticalResponse;
	const float InnerGlow = EnableInnerGlow && HasKeyArtLight
		? 1.0f - exp(-max(P.InnerGlowStrength, 0.0f)
			* WeatherFeatureResponse * InnerGlowStructuralResponse)
		: 0.0f;
	// A5 powder: a deliberately low-amplitude local-thickness response. The
	// boundary gate prevents thick interiors from becoming uniform white cream.
	const float PowderLocalOpticalResponse = 1.0f - exp(
		-max(P.PowderDensity, 0.0f) * Features.TauLocal);
	const float PowderAngularResponse = lerp(0.25f, 1.0f, saturate(-MuForward));
	const float PowderStructuralResponse = PowderLocalOpticalResponse
		* PowderAngularResponse
		* BoundaryGradient;
	const float Powder = EnablePowder && HasKeyArtLight
		? 1.0f - exp(-max(P.PowderStrength, 0.0f)
			* WeatherFeatureResponse * PowderStructuralResponse)
		: 0.0f;
	float3 AnalyticPaletteColor = lerp(P.ShadowColor, P.BodyColor, WrapLight);
	AnalyticPaletteColor = lerp(
		AnalyticPaletteColor,
		P.SunlitColor,
		LuminanceResponse * WrapLight);
	const float3 TypeTint = lerp(P.BodyColor, P.SunlitColor, PaletteCloudType);
	AnalyticPaletteColor = lerp(
		AnalyticPaletteColor,
		TypeTint,
		EnableWeather ? saturate(P.TypeColorStrength) : 0.0f);
	AnalyticPaletteColor = lerp(
		AnalyticPaletteColor,
		P.StormColor,
		PaletteStorm * P.StormDarkening);
	const float3 AnalyticBaseColor = AnalyticPaletteColor
		* lerp(0.35f, 1.0f, LuminanceResponse);
	const float LUTVerticalCoordinate = P.ColorLUTVerticalAxis == 1u
		? Features.NormalizedHeight
		: OpticalDepthResponse;
	const float LUTSliceCoordinate = P.ColorLUTSliceAxis == 1u
		? PaletteStorm
		: PaletteCloudType;
	float3 SampledLUTBaseColor = 0.0f;
	SampledLUTBaseColor = max(Features.SampledLUTBaseColor, 0.0f);
	// The LUT is a chromatic interpretation of the physical result. In the
	// default PreservePhysicalLuminance mode it cannot replace physical energy:
	// its RGB is normalized to the already integrated premultiplied luminance.
	// AbsoluteBaseColor remains an explicit profile opt-in for legacy looks.
	const float3 ContinuousBaseColor = lerp(
		AnalyticBaseColor,
		SampledLUTBaseColor,
		P.UseColorLUT != 0u ? saturate(P.ColorLUTStrength) : 0.0f);
	const float PhysicalPremultipliedLuminance = TACloudLuminance(PhysicalPremultiplied);
	const float ContinuousBaseLuminance = TACloudLuminance(max(ContinuousBaseColor, 0.0f));
	// A black/invalid palette entry has no usable chromatic direction. Preserve
	// the physical baseline instead of normalizing it into a black energy sink.
	const float3 PreservedLuminanceBaseCP = ContinuousBaseLuminance > 1.0e-5f
		? TACloudArtMatchLuminance(
			ContinuousBaseColor,
			PhysicalPremultipliedLuminance)
		: PhysicalPremultiplied;
	const float3 AbsoluteBaseCP = max(ContinuousBaseColor, 0.0f) * Coverage;
	const float3 InterpretedBaseCP = P.ColorLUTColorMode == 1u
		? PreservedLuminanceBaseCP
		: AbsoluteBaseCP;
	const float3 A4BaseCP = lerp(
		InterpretedBaseCP,
		PhysicalPremultiplied,
		saturate(P.PhysicalContribution));
	// Apply dark edges as bounded attenuation plus chroma tint. This cannot
	// create a black outline or increase luminance, even with extreme tint RGB.
	const float3 NonNegativeShadowTint = max(P.ShadowColor, 0.0f);
	const float ShadowTintLuminance = TACloudLuminance(NonNegativeShadowTint);
	const float3 ShadowChromaticity = ShadowTintLuminance > 1.0e-4f
		? clamp(NonNegativeShadowTint / ShadowTintLuminance, 0.25f, 4.0f)
		: 1.0f;
	float3 SameLuminanceTintedBase = A4BaseCP * ShadowChromaticity;
	const float BaseLuminance = TACloudLuminance(A4BaseCP);
	const float TintedBaseLuminance = TACloudLuminance(SameLuminanceTintedBase);
	SameLuminanceTintedBase *= TintedBaseLuminance > 1.0e-4f
		? BaseLuminance / TintedBaseLuminance
		: 1.0f;
	const float3 A4CP = max(
		0.0f,
		lerp(A4BaseCP, SameLuminanceTintedBase, DarkEdge)
			* (1.0f - DarkEdge));
	const float3 SilverContributionCP = TACloudArtTintDirectBudget(
		Features.DirectPremultiplied,
		P.SilverColor) * Silver;
	const float3 PowderContributionCP = TACloudArtTintDirectBudget(
		Features.DirectPremultiplied,
		P.SunlitColor) * Powder;
	const float3 A5CP = A4CP + SilverContributionCP + PowderContributionCP;
	// Convex lobes receive a small luminance-preserving saturation increase and
	// bounded lift. Concave grooves receive a same-luminance cold tint followed
	// by bounded attenuation; neither response can become a hard outline.
	const float A5Luminance = TACloudLuminance(A5CP);
	float3 A6CP = max(
		0.0f,
		lerp(
			A5Luminance.xxx,
			A5CP,
			1.0f + max(P.ConvexSaturation, 0.0f) * ConvexAmount));
	A6CP *= 1.0f + max(P.ConvexLift, 0.0f) * ConvexAmount;
	const float PreConcaveLuminance = TACloudLuminance(A6CP);
	float3 SameLuminanceConcaveTint = A6CP * ShadowChromaticity;
	const float ConcaveTintLuminance = TACloudLuminance(SameLuminanceConcaveTint);
	SameLuminanceConcaveTint *= ConcaveTintLuminance > 1.0e-4f
		? PreConcaveLuminance / ConcaveTintLuminance
		: 1.0f;
	const float ConcaveTintResponse = 1.0f - exp(
		-max(P.ConcaveTintStrength, 0.0f) * ConcaveAmount);
	const float ConcaveDarkResponse = 0.75f * (1.0f - exp(
		-max(P.ConcaveDarkening, 0.0f) * ConcaveAmount));
	A6CP = max(
		0.0f,
		lerp(A6CP, SameLuminanceConcaveTint, ConcaveTintResponse)
			* (1.0f - ConcaveDarkResponse));
	const float3 InnerGlowContributionCP = TACloudArtTintDirectBudget(
		Features.DirectPremultiplied,
		P.InnerGlowColor) * InnerGlow;
	const float3 A7CP = A6CP + InnerGlowContributionCP;
	float3 ArtCP = A7CP;
	// Lifecycle already shaped density before transport and is retained here as
	// a continuous LUT/debug coordinate only. Applying it again to radiance
	// would double-count formation/dissipation and make the base-color contract
	// depend on a second, unphysical brightness curve.
	ArtCP = max(0.0f, ArtCP);
	const float ArtLuminance = TACloudLuminance(ArtCP);
	const float MaximumLuminance = PhysicalPremultipliedLuminance
		* max(P.EnergyLimit, 1.0f);
	const float EnergyLimitScale = ArtLuminance > MaximumLuminance
		? MaximumLuminance / max(ArtLuminance, 1.0e-4f)
		: 1.0f;
	ArtCP *= EnergyLimitScale;
	const float FinalArtStrength = saturate(P.Strength * DistanceArtResponse);
	const float3 FinalContinuousArtCP = lerp(
		PhysicalPremultiplied,
		ArtCP,
		FinalArtStrength);
    return FinalContinuousArtCP;
}
#endif
