#include "ReShadeUI.fxh"
#include "ReShade.fxh"
#include "KataeFuncs.fxh"

uniform float Power <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 5;
> = 1;

uniform float ColorSharpness <
	ui_type = "slider"; 
	ui_min = 0.0001; 
	ui_max = 5;
> = 1.5;

uniform float DepthPower <
	ui_type = "slider"; 
	ui_min = -5; 
	ui_max = 5;
> = 0.7;

uniform float DepthBias <
	ui_type = "slider"; 
	ui_min = -50; 
	ui_max = 50;
> = 0.1;

uniform float NormalsBiasPower <
	ui_type = "slider"; 
	ui_min = 0.001; 
	ui_max = 5;
> = 0.3;

uniform float NormalsBias <
	ui_type = "slider"; 
	ui_min = -20; 
	ui_max = 20;
> = 0.3;

uniform float NormalsSubtraction <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 1;
> = 0.1;

uniform float DepthMinimum <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 1;
> = 0.7;

uniform float DivisionFactor <
	ui_type = "slider"; 
	ui_min = 1; 
	ui_max = 300;
> = 4;

uniform float2 PixelSize = float2(2,2);

uniform float3 DarkColor <__UNIFORM_COLOR_FLOAT3> = float3(0, 0.08, 0);

uniform float3 BrightColor <__UNIFORM_COLOR_FLOAT3> = float3(1, 0.95, 0.82);

float3 PS_Obra(float4 SV_POSITION : SV_Position, float2 TexCoord : TEXCOORD) : SV_Target
{
	float3 ret = 0;
	
	float2 ScaledResolution = ScreenResolution / PixelSize;
	
	float FinalNormalsBias = length(sqrt_s(EstimateSurfaceNormal(TexCoord), NormalsBiasPower));
	FinalNormalsBias = saturate(max(AlmostZero, length(FinalNormalsBias) - NormalsSubtraction));
	
	FinalNormalsBias = FinalNormalsBias * NormalsBias;
	
	float DivisionNew = round(DivisionFactor);
	
	float2 UV = TexCoord;
	UV *= ScaledResolution;
	UV = round(UV);
	UV /= ScaledResolution;
	
	float3 Color = tex2D(SamplerColor, UV).rgb;
	float3 ColorNew = sqrt_s(2 * (Color - 0.5), ColorSharpness);
	ColorNew = ColorNew / 2 + 0.5;
	float ColorLength;
	ColorLength = saturate(length(ColorNew));
	//ColorLength = saturate(dot(1, Color));
	
	ColorLength = pow(ColorLength, Power);
	
	float PixelSizeSquared = PixelSize.x * PixelSize.y;
	
	float Depth = tex2D(SamplerDepth, UV).r;
	
	Depth = 1 - Depth;
	
	Depth = max(DepthMinimum, Depth);
	
	Depth = pow(Depth, DepthPower);
	
	float CurrentPixel = 
		round(UV.y * ScaledResolution.x * ScaledResolution.y)
		+ round(UV.x * ScaledResolution.x)
		+ ((round(UV.y * ScaledResolution.y) % 2) * DivisionNew/2)
	;
	

	
	ret = exp2(CurrentPixel % DivisionNew) / DivisionNew;
	
	//ret = pow(ret, Power);

	ret = ret <= (ColorLength + DepthBias * Depth + FinalNormalsBias);
	
	ret = lerp(DarkColor, BrightColor, ret);
	
	//ret.rg = 0.3 + 250 * EstimateSurfaceNormal(TexCoord);
	//ret.b = 0 * Depth;
	//ret = saturate(NormalsBias * length(sqrt_s(EstimateSurfaceNormal(TexCoord), NormalsBiasPower)) - NormalsSubtraction);
	
	return ret;
}

technique K_Obra
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Obra;
	}
}