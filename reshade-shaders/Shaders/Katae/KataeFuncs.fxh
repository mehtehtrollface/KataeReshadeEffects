#include "ReShadeUI.fxh"
#include "ReShade.fxh"

uniform float2 ScreenResolution < hidden = true; > = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
uniform float AlmostZero < hidden = true; > = 0.00001;

//#define float4(a,x) (float4(a.r,a.g,a.b,x))

float2 UV_To_Res(float2 uv){return uv * ScreenResolution;}
float2 Res_To_UV(float2 res){return res / ScreenResolution;}

texture2D TexColor : COLOR;
sampler SamplerColor
{
	Texture = TexColor;
};
texture2D TexDepth : DEPTH;
sampler SamplerDepth
{
	Texture = TexDepth;
};

// basic formula to estimate the surface normal
// mostly for internal usage
float2 EstimateSurfaceNormal(float2 UV)
{
	float2 ret = 0;
	
	float DepthUpRight =   tex2Dfetch(SamplerDepth, UV_To_Res(UV) + int2(1, 0)).r;
	float DepthUpLeft =    tex2Dfetch(SamplerDepth, UV_To_Res(UV) + int2(0, 0)).r;
	float DepthDownRight = tex2Dfetch(SamplerDepth, UV_To_Res(UV) + int2(1, 1)).r;
	float DepthDownLeft =  tex2Dfetch(SamplerDepth, UV_To_Res(UV) + int2(0, 1)).r;
	
	//ret = float2(DepthLeft - DepthRight, DepthUp - DepthDown);
	ret = float2(
		-2 + 1 * (DepthUpLeft/DepthUpRight + DepthDownLeft/DepthDownRight)
		,
		-2 + 1 * (DepthUpLeft/DepthDownLeft + DepthUpRight/DepthDownRight)
	);
	
	return ret;
}

// Equivalent to power() but preserves the sign. 
// Mostly intended to resolve the glitching that happens
// when using the standard sqrt()
float4 sqrt_s(float4 x, float power = 0.5)
{
	float4 signs;
	signs.x = (x.x < 0) ? -1 : 1; // this feels wrong
	signs.y = (x.y < 0) ? -1 : 1;
	signs.z = (x.z < 0) ? -1 : 1;
	signs.w = (x.w < 0) ? -1 : 1; // very wrong
	float4 absx = abs(x);
	float4 ret = pow(absx, power);
	ret *= signs;
	
	return ret;
}

float3 sqrt_s(float3 x, float power = 0.5)
{
	return sqrt_s(float4(x.x, x.y, x.z, 0), power).xyz;
}

float2 sqrt_s(float2 x, float power = 0.5)
{
	return sqrt_s(float4(x.x, x.y, 0, 0), power).xy;
}

float sqrt_s(float x, float power = 0.5)
{
	return sqrt_s(float4(x, 0, 0, 0), power).x;
}

// approximate index of the pixel
float PixelIndex(float2 uv)
{
	float ind = uv.y * ScreenResolution.y * ScreenResolution.x;
	ind += uv.x * ScreenResolution.x;
	
	return ind;
}

// returns the highest and lowest values
// of float1[4] array, or from the components of a float4
int2 HighestLowest(float inp[4])
{
	float Highest = inp[0];
	float Lowest = inp[0];
	int HighestIndex = 0;
	int LowestIndex = 0;
	for(int i=1;i<4;i++){
		if(inp[i] > Highest){
			HighestIndex = i;
			Highest = inp[i];
		}
		if(inp[i] < Lowest){
			LowestIndex = i;
			Lowest = inp[i];
		}
	}
	return int2(HighestIndex, LowestIndex);
}

int2 HighestLowest(float4 inp)
{
	return HighestLowest({inp.x, inp.y, inp.z, inp.w});
}

// normalize by highest component
// mostly useful to avoid float >1 for color multiplication
float4 normalize_comp(float4 inp)
{
	float highest = max(max(inp.x, inp.y), max(inp.z, inp.w));
	return inp * (1 / highest);
}
float3 normalize_comp(float3 inp)
{
	float highest = max(max(inp.x, inp.y), inp.z);
	return inp * (1 / highest);
}
float2 normalize_comp(float2 inp)
{
	float highest = max(inp.x, inp.y);
	return inp * (1 / highest);
}



void AccumulateStorage2D(storage2D target, int2 uv, float4 color)
{
	//barrier();
	float4 currcol = tex2Dfetch(target, uv);
	//barrier();
	tex2Dstore(target, uv, color + currcol);
	//barrier();
	memoryBarrier();
}



float2 EstimateReflectionUV(float2 inuv, float distance)
{
	float2 ret;
	
	ret = inuv;
	
	float2 surface = EstimateSurfaceNormal(inuv);
	
	return ret;
}