
#include "KataeFuncs.fxh"

uniform bool UseNewMethod <
	ui_bind = "OUTLINE_USENEWMETHOD";
> = 1;
#ifndef OUTLINE_USENEWMETHOD
	#define OUTLINE_USENEWMETHOD 0
#endif

uniform float2 SeekRange = float2(1,1);
uniform float DepthTolerance <ui_type = "slider";> = 0.1;
uniform float InterpFactor = 1;
uniform float CalibrationPower = 3;
uniform float3 OutlineColor <__UNIFORM_COLOR_FLOAT3> = 0;


float Calibrate_Old(float A, float B, float C, float D)
{
	float InputMax = max(max(max(abs(A - B), abs(A - C)), max(abs(A - D), abs(B - C))), max(abs(B - D), abs(C - D)));
	
	return pow(InputMax, CalibrationPower);
}

float Calibrate(float A, float B, float C, float D)
{
	float Minimum = min(min(A,B), min(C,D));
	
	return log10(1 / Minimum);
}

float3 PS_BasicOutline(float4 SV_POSITION : SV_Position, float2 TexCoord : TEXCOORD) : SV_Target
{
	float3 ret;
	
	float2 uv = TexCoord;
	
	float2 NewPixelSize = SeekRange / float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	
	
	#if OUTLINE_USENEWMETHOD == 1
	float2 UVCorner1 = saturate(uv);
	float2 UVCorner2 = saturate(uv + NewPixelSize * float2(1,0));
	float2 UVCorner3 = saturate(uv + NewPixelSize * float2(0,1));
	float2 UVCorner4 = saturate(uv + NewPixelSize * float2(1,1));
	#else
	float2 UVCorner1 = saturate(uv + NewPixelSize / float2(2,2));
	float2 UVCorner2 = saturate(uv + NewPixelSize / float2(-2,2));
	float2 UVCorner3 = saturate(uv + NewPixelSize / float2(2,-2));
	float2 UVCorner4 = saturate(uv + NewPixelSize / float2(-2,-2));
	#endif
	
	float DepthCorner1 = tex2D(SamplerDepth, UVCorner1).r;
	float DepthCorner2 = tex2D(SamplerDepth, UVCorner2).r;
	float DepthCorner3 = tex2D(SamplerDepth, UVCorner3).r;
	float DepthCorner4 = tex2D(SamplerDepth, UVCorner4).r;
	
	float CurrentDepth = tex2D(SamplerDepth, uv+NewPixelSize*float2(0.5,0.5)).r;
	
	float2 UVCorner[4] = {UVCorner1, UVCorner2, UVCorner3, UVCorner4};
	float DepthCorner[4] = {DepthCorner1, DepthCorner2, DepthCorner3, DepthCorner4};

	float CalibrationFactor = Calibrate(DepthCorner1, DepthCorner2, DepthCorner3, DepthCorner4);

	float HighestDepth = 0;
	
	for(int i = 0; i<4; i++)
	{
		float DepthDiff = DepthCorner[i] / CurrentDepth;
		DepthDiff = max(DepthDiff, 1 / DepthDiff);
		DepthDiff = pow(DepthDiff, CalibrationFactor + CalibrationPower);
		if (DepthDiff > HighestDepth)
		{
			HighestDepth = DepthDiff;
		}
	}
	
	
	
	HighestDepth = HighestDepth - 1;
	
	ret = tex2D(SamplerColor, uv).rgb;
	
	ret = lerp(ret, OutlineColor, sqrt(sqrt(saturate((HighestDepth - DepthTolerance) * InterpFactor))));
	
	//ret = CurrentDepth;
	
	//ret = HighestDepth;
	//ret = CalibrationFactor;
	
	return ret;
}

technique K_BasicOutline
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_BasicOutline;
	}
}