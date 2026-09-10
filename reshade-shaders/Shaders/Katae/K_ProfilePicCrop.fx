#include "KataeFuncs.fxh"

uniform float4 SquareCropColor <__UNIFORM_COLOR_FLOAT4> = float4(0, 0, 0, 0.2);

uniform float4 CircleCropColor <__UNIFORM_COLOR_FLOAT4> = float4(0, 0, 0, 0.2);

uniform bool InScreenshot <source = "screenshot";>;

float3 PS_PPCrop(float4 SV_POSITION : SV_Position, float2 TexCoord : TEXCOORD) : SV_Target
{
	float3 ret = 0;
	
	float2 ScreenCenter = ScreenResolution * 0.5;
	
	float2 ScreenPos = SV_POSITION.xy - ScreenCenter;
	
	float Cutoff = 0.5 * min(BUFFER_WIDTH, BUFFER_HEIGHT);
	
	float3 Color = tex2D(SamplerColor, TexCoord).rgb;
	
	float2 SquareTemp = abs(ScreenPos);
	
	float SquareLerp = ceil(saturate(max(SquareTemp.x, SquareTemp.y) - Cutoff));
	SquareLerp *= (InScreenshot ? 1 : SquareCropColor.a);
	
	ret = lerp(Color, SquareCropColor.rgb, SquareLerp);
	
	float CircleLerp = saturate(length(ScreenPos) - Cutoff);
	CircleLerp *= (InScreenshot ? 0 : CircleCropColor.a);
	
	ret = lerp(ret, CircleCropColor.rgb, CircleLerp);
	
	//ret.xy = ScreenPos * 0.001;
	
	return ret;
}

technique K_ProfilePicCrop
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_PPCrop;
	}
}