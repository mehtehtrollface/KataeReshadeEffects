

#include "ReShadeUI.fxh"
#include "ReShade.fxh"
#include "KataeFuncs.fxh"

#ifndef K_PIXCALIBRATIONMETHOD
	#define K_PIXCALIBRATIONMETHOD 1
#endif

uniform float2 PixelSize = float2(8,8);
uniform float RoundingMultiplier <
	ui_type = "slider";
	ui_min = 0.1;
	ui_max = 512;
> = 1;

uniform float CalibrationMinimum <
	ui_type = "slider";
	ui_min = -10;
	ui_max = 100;
> = 10;

uniform float DepthMinimum <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 1;
> = 0.01;

uniform float IgnoreAlphaThreshold <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 1;
> = 0.7;

uniform float IgnoreAlphaBias <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 10;
> = 0.1;

uniform bool DisableIgnoringInScreenshot <
	ui_bind = "AllowAlphaInScreenshots";
> = 1;
uniform bool InScreenshot <source = "screenshot";>;

float Calibrate(float A, float B, float C, float D)
{
	float InputMax = RoundingMultiplier * max(
		max(
			max(abs(A - B), abs(A - C)), 
			max(abs(A - D), abs(B - C))), 
		max(abs(B - D), abs(C - D))
	);
	
	return 1 / max(CalibrationMinimum, log2(InputMax));
}

// The new calibration formula based on its performance in the outline shader
// There seems to be too much of a tradeoff between close and far ranges
float Calibrate_New(float A, float B, float C, float D)
{
	float Minimum = min(min(A,B), min(C,D));
	
	return max(log2(1 / Minimum), CalibrationMinimum);
}

float Calibrate_Median(float A, float B, float C, float D)
{
	float4 val = float4(A,B,C,D);
	float2 min2d = min(val.xy, val.zw);
	float2 max2d = max(val.xy, val.zw);
	float median1 = max(min(min2d.x, min2d.y), min(max2d.x, max2d.y));
	float median2 = min(max(min2d.x, min2d.y), max(max2d.x, max2d.y));
	return max(((median1 + median2)), CalibrationMinimum);
}

float Calibrate_Extreme(float A, float B, float C, float D)
{
	float maxval = max(max(A,B),max(C,D));
	float minval = min(min(A,B),min(C,D));
	
	return maxval - maxval;
}

float DepthDiff(float A, float B, float Calibration)
{
	float ret = max(A/B, B/A);
	ret *= max(1/Calibration, CalibrationMinimum);
	ret = round(ret/RoundingMultiplier);
	return ret;
	//return round((max(A/B, B/A) * max(1/Calibration, CalibrationMinimum)) * RoundingMultiplier) / RoundingMultiplier;
}

float3 PS_NeoPixelizer(float4 SV_POSITION : SV_Position, float2 TexCoord : TEXCOORD) : SV_Target
{
	float3 ret = 0;
	
	float2 uv = TexCoord;
	
	//DepthMinimum = AlmostZero;
	
	float2 NewPixelSize = PixelSize / float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	
	//NewPixelSize *= 1 + sqrt_s(EstimateSurfaceNormal(TexCoord), 0.1);

	float CurrentDepth = max(AlmostZero, tex2D(SamplerDepth, TexCoord).r);
	
	float4 testres = tex2D(SamplerColor, uv).rgba;
	
	uv = round(uv / NewPixelSize) * NewPixelSize;
	
	float2 UVCorner1 = uv + NewPixelSize / float2(2,2);
	float2 UVCorner2 = uv + NewPixelSize / float2(2,-2);
	float2 UVCorner3 = uv + NewPixelSize / float2(-2,2);
	float2 UVCorner4 = uv + NewPixelSize / float2(-2,-2);
	
	float DepthCorner1 = max(AlmostZero, tex2D(SamplerDepth, UVCorner1).r);
	float DepthCorner2 = max(AlmostZero, tex2D(SamplerDepth, UVCorner2).r);
	float DepthCorner3 = max(AlmostZero, tex2D(SamplerDepth, UVCorner3).r);
	float DepthCorner4 = max(AlmostZero, tex2D(SamplerDepth, UVCorner4).r);
	
	float AlphaCorner1 = tex2D(SamplerColor, UVCorner1).a;
	float AlphaCorner2 = tex2D(SamplerColor, UVCorner2).a;
	float AlphaCorner3 = tex2D(SamplerColor, UVCorner3).a;
	float AlphaCorner4 = tex2D(SamplerColor, UVCorner4).a;
	
	float2 UVCorner[4] = {UVCorner1, UVCorner2, UVCorner3, UVCorner4};
	float DepthCorner[4] = {DepthCorner1, DepthCorner2, DepthCorner3, DepthCorner4};
	float AlphaCorner[4] = {AlphaCorner1, AlphaCorner2, AlphaCorner3, AlphaCorner4};
	
	int BestIndex = -1;
	float BestDepth = 1000;
	
	float Calibration = 0;
	
	#if K_PIXCALIBRATIONMETHOD == 0
	Calibration = Calibrate(DepthCorner1, DepthCorner2, DepthCorner3, DepthCorner4);
	#elif K_PIXCALIBRATIONMETHOD == 1
	Calibration = Calibrate_New(DepthCorner1, DepthCorner2, DepthCorner3, DepthCorner4);
	#elif K_PIXCALIBRATIONMETHOD == 2
	Calibration = Calibrate_Median(DepthCorner1, DepthCorner2, DepthCorner3, DepthCorner4);
	#elif K_PIXCALIBRATIONMETHOD == 3
	Calibration = Calibrate_Extreme(DepthCorner1, DepthCorner2, DepthCorner3, DepthCorner4);
	#else
	
	#endif

	//Calibration = 0;
	
	for(int i = 0; i<4; i++)
	{
		float DepthDifference = DepthDiff(DepthCorner[i], CurrentDepth, Calibration);
			DepthDifference += IgnoreAlphaBias * 
				saturate(AlphaCorner[i] - 
					(IgnoreAlphaThreshold + DisableIgnoringInScreenshot * InScreenshot)
				);

		if (DepthDifference < BestDepth)
		{
			BestIndex = i;
			BestDepth = DepthDifference;
		}
	}
	
	if (BestIndex == -1) BestIndex = 0;
	
	ret = tex2D(SamplerColor, UVCorner[BestIndex]).rgb;
	
	//ret = BestDepth * 256;
	float2 testuv = float2(UVCorner[BestIndex].rg);
	testuv -= TexCoord;
	//ret = float3(testuv.r, testuv.g, 0) * 100;
	
	
	
	//ret = lerp(testres.rgb, float3(1,0,0), saturate(testres.a - 0.5));
	//ret = lerp(0, float3(1,0,0), saturate(testres.a - 0.9) * 5);
	//ret = lerp(0, float3(1,0,0), CurrentDepth * 256);
	//ret = tex2D(SamplerDepth, TexCoord).rgb * 256;
	
	return ret;
}

technique K_NeoPixelizer
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_NeoPixelizer;
	}
}