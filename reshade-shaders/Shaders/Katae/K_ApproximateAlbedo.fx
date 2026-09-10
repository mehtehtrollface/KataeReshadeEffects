#include "KataeFuncs.fxh"

uniform bool Test = false;
uniform float DenormalizationScale <
	ui_type = "slider";
	ui_min = 0;
	ui_max = 2;
> = 0.3;
uniform float Multiplier <
	ui_type = "slider";
	ui_min = 0;
	ui_max = 2;
> = 0.7;
uniform float DarknessEqualizer <
	ui_type = "slider";
	ui_min = -2;
	ui_max = 2;
> = -0.1;

#ifndef TargetRT
	#define TargetRT RenderTarget6
#endif

texture2D TexAlbedo{
	Width=BUFFER_WIDTH;
	Height=BUFFER_HEIGHT;
	Format=BUFFER_COLOR_FORMAT;
};
storage2D AlbedoStorage
{
	Texture = TexAlbedo;
};
sampler SamplerAlbedo
{
	Texture = TexAlbedo;
};

void CS_ApproximateAlbedo(uint3 GTID : SV_GroupThreadID, uint3 DTID : SV_DispatchThreadID)
{
	float3 Color = tex2Dfetch(SamplerColor, DTID.xy).rgb;
	float Length = length(Color);
	Length = sqrt_s(Length, DenormalizationScale + DarknessEqualizer * saturate(1 - Length));
	Color = normalize(Color) * Length * Multiplier;
	tex2Dstore(AlbedoStorage, float2(DTID.x, DTID.y), float4(Color.r,Color.g,Color.b,1));
}

float3 PS_AlbedoDemo(float4 SV_POSITION : SV_Position, float2 TexCoord : TEXCOORD) : SV_Target
{
	if(!Test) discard;
	
	return tex2D(SamplerAlbedo, TexCoord).rgb;
}

technique K_ApproximateAlbedo
{
	pass p0
	{
		ComputeShader = CS_ApproximateAlbedo<32, 32, 1>;
		DispatchSizeX = BUFFER_WIDTH / 32;
		DispatchSizeY = BUFFER_HEIGHT / 32;
	}
	pass p1
	{
		VertexShader = PostProcessVS;
		//PixelShader = PS_AlbedoDemo;
		TargetRT = TexAlbedo;
	}
	
	
}
technique K_ApproximateAlbedoTest
{
	pass p0
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_AlbedoDemo;
	}
}