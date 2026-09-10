
#include "ReShadeUI.fxh"
#include "ReShade.fxh"
#include "KataeFuncs.fxh"

uniform float RoundingFactor = 32;
uniform float Speed = -2;
uniform float Lines = 1000;
uniform float CRTOpacity = 0.2;

uniform float RunTime <source = "timer";>;
uniform float4 Date <source = "date";>;

float3 PS_RetroColors(float4 SV_POSITION : SV_Position, float2 TexCoord : TEXCOORD) : SV_Target
{
	float3 Color = tex2D(SamplerColor, TexCoord).rgb * 256;
	
	Color = round(Color/RoundingFactor) * RoundingFactor;
	
	Color = Color * (1 + CRTOpacity * sin(TexCoord.y * Lines + Speed * (RunTime / 1000)));
	
	return Color / 256;
}

technique K_RetroColors
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_RetroColors;
	}
}