#include "KataeFuncs.fxh"

#pragma reshade skipoptimization

uniform int FunctionToDebug <
    ui_type = "combo";
    ui_items = "SignedSqrt\0SurfaceNormal\0DepthTest\0QuadIndex\0NormalizeByComponent\0";
> = 0;

float3 PS_KataeDebug(float4 SV_POSITION : SV_Position, float2 TexCoord : TEXCOORD) : SV_Target
{
	float3 Color = tex2D(SamplerColor, TexCoord).rgb;
	float Depth = tex2D(SamplerDepth, TexCoord).r;
	float2 ScaledRes = UV_To_Res(TexCoord);
	float3 ret = Color;
	
	switch(FunctionToDebug){
		case 0: // Signed sqrt
			ret.b = 0;
			float2 newuv = UV_To_Res(TexCoord) / 16;
			newuv = sin(newuv);
			ret.rg = 0.5 * sqrt_s(newuv) + 0.5;
			//ret.rg = sqrt(newuv)
			break;
		
		
		case 1: // SurfaceNormal
			ret.b = 0;
			ret.rg = 0.5 + sqrt_s(EstimateSurfaceNormal(TexCoord), 1);
			break;
		
		case 2: // Depth test
			ret = sqrt_s(tex2D(SamplerDepth, TexCoord).rgb);
			break;
			
		case 3: // Pixel index test
			//ret.rg = round(ScaledRes % 2);
			float2 Modulo = saturate(round(ScaledRes % 2));
			int ThisPixel = floor(Modulo.y * 2.01 + Modulo.x * 1.01);
			if(ThisPixel>=3){
				ret = float3(0,0,1); break;
			}
			if(ThisPixel>=2){
				ret = float3(0,1,0); break;
			}
			if(ThisPixel>=1){
				ret = float3(1,1,0); break;
			}
			if(ThisPixel>=0){
				ret = float3(1,0,0); break;
			}
			//ret = float3(1,1,1);
			//ret.rg = Modulo;
			break;
			
		case 4: // normalize by component
			ret = normalize_comp(Color);
			break;
		
		default:
			break;
	}
	
	return ret;
}

technique K_Debug
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_KataeDebug;
	}
}