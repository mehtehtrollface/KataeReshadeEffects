
#include "ReShadeUI.fxh"
#include "ReShade.fxh"
#include "KataeFuncs.fxh"

uniform float3 DarkColor <__UNIFORM_COLOR_FLOAT3> = float3(0, 0, 0);

uniform float ThresholdFull <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 2;
> = 1.0;
uniform float ThresholdHigh <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 2;
> = 0.75;
uniform float ThresholdMed <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 2;
> = 0.5;
uniform float ThresholdLow <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 2;
> = 0.25;

uniform float MultiFull <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 10;
> = 1.0;
uniform float MultiHigh <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 10;
> = 1.25;
uniform float MultiMed <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 10;
> = 1.6;
uniform float MultiLow <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 10;
> = 2;
uniform float MultiMin <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 10;
> = 2;
uniform float MiddlePointTolerance <
	ui_type = "slider"; 
	ui_min = 0; 
	ui_max = 1;
> = 0.05;
uniform float DarkPixelBias <
	ui_type = "slider"; 
	ui_min = 0.0001; 
	ui_max = 10;
> = 1;
uniform bool AlwaysNormalize <> = false;
uniform bool UseMultipliers <> = true;

float3 PS_Dithering(float4 SV_POSITION : SV_Position, float2 TexCoord : TEXCOORD) : SV_Target
{
	float2 ScaledRes = UV_To_Res(TexCoord);
	float2 RoundedUV = Res_To_UV(round(ScaledRes / 2) * 2);
	float2 Modulo = saturate(round(ScaledRes % 2));
	int ThisPixel = floor(Modulo.y * 2.01 + Modulo.x * 1.01);
	float3 UpLeft = tex2D(SamplerColor, RoundedUV).rgb;
	float3 UpRight = tex2D(SamplerColor, RoundedUV, int2(1,0)).rgb;
	float3 DownLeft = tex2D(SamplerColor, RoundedUV, int2(0,1)).rgb;
	float3 DownRight = tex2D(SamplerColor, RoundedUV, int2(1,1)).rgb;
	
	float3 Colors[4] = {
		UpLeft,UpRight,DownLeft,DownRight
	};
	
	
	
	float Lengths[4] = {
		length(UpLeft), 
		length(UpRight), 
		length(DownLeft), 
		length(DownRight)
	};
	float Average = 0.25 * 
		(Lengths[0] + Lengths[1] + Lengths[2] + Lengths[3]);
		
	float3 ThisColor = Colors[ThisPixel];
	float ThisLength = Lengths[ThisPixel];
	if(!UseMultipliers){
		if(AlwaysNormalize){
			ThisColor = normalize(ThisColor);
		}else{
			if(ThisLength < 1){
				//ThisColor = normalize(ThisColor);
			}
		}
	}
	
	if(Average > ThresholdFull)
	{
		return ThisColor * (UseMultipliers?MultiFull:1);
		//return 1;
	}
	if(Average > ThresholdHigh)
	{
		if(HighestLowest(Lengths).y == ThisPixel)
			return DarkColor;
		else
			return ThisColor * (UseMultipliers?MultiHigh:1);
		//return 0.75;
	}
	if(Average > ThresholdMed)
	{
		float ForwardSlash = dot(DownLeft, UpRight);
		float BackSlash = dot(UpLeft, DownRight);
		if((ForwardSlash - BackSlash) < MiddlePointTolerance){
			if(ThisPixel == 0 || ThisPixel == 3){
				return ThisColor * (UseMultipliers?MultiMed:1);
			} else return DarkColor;
		}else{
			if(ThisPixel == 1 || ThisPixel == 2){
				return ThisColor * (UseMultipliers?MultiMed:1);
			} else return DarkColor;
		}
		
		return 0.5;
	}
	if(Average > ThresholdLow)
	{
		if(HighestLowest(Lengths).x == ThisPixel)
			return ThisColor * (UseMultipliers?MultiLow:1);
		else
			return DarkColor;
		//return 0.25;
	}
	
	if(PixelIndex(TexCoord) % (DarkPixelBias / max(AlmostZero, ThisLength)) < 1)
		return ThisColor * (UseMultipliers?MultiMin:1);
	
	return DarkColor;
}

technique K_DitheredQuads
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Dithering;
	}
}