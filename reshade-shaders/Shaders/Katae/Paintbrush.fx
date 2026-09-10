#include "KataeFuncs.fxh"

#ifndef KD_TOGGLEDRAWING
	#define KD_TOGGLEDRAWING 0x58
#endif
#ifndef KD_WIPEDRAWING
	#define KD_WIPEDRAWING 0x56
#endif
#ifndef KD_DEBUGMOUSE
	#define KD_DEBUGMOUSE 0
#endif
#ifndef KD_SMOOTHENING
	#define KD_SMOOTHENING 3
#endif

uniform bool bIsDrawing < 
	source = "key"; 
	keycode = KD_TOGGLEDRAWING; 
	//mode = "toggle"; 
> = false;

uniform bool bWipe < 
	source = "key"; 
	keycode = KD_WIPEDRAWING; 
> = false;

uniform float Radius <
	ui_type = "slider";
	ui_min = 1;
	ui_max = 100;
> = 4;

uniform float PaintbrushSize<
	ui_type = "slider";
	ui_min = 1;
	ui_max = 2000;
> = 75;


uniform float4 BrushColor <__UNIFORM_COLOR_FLOAT4> = float4(1, 0.75, 0, 0.6);

uniform float2 MousePos <source="mousepoint";>;

texture2D TexBrush <
	source = "Katae/Paintbrush.png";
>{Width=100;Height=100;Format=R8G8B8A8;};
sampler SamplerPaintbrush
{
	Texture = TexBrush;
};

texture2D TexDrawing{
	Width=BUFFER_WIDTH;
	Height=BUFFER_HEIGHT;
	Format=RGBA32F;
};
storage2D DrawingStorage
{
	Texture = TexDrawing;
};
sampler SamplerDrawing
{
	Texture = TexDrawing;
};

#if KD_DEBUGMOUSE == 1
texture2D TexMouse{
	Width=BUFFER_WIDTH;
	Height=BUFFER_HEIGHT;
	Format=RGBA32F;
};
storage2D MouseStorage
{
	Texture = TexMouse;
};
sampler SamplerMouse
{
	Texture = TexMouse;
};
#endif

[shader("compute")]
void CS_WipeTex(uint3 GTID : SV_GroupThreadID, uint3 DTID : SV_DispatchThreadID)
{
	if(bWipe){
		tex2Dstore(DrawingStorage, float2(DTID.x, DTID.y), 0);
		#if KD_DEBUGMOUSE == 1
		tex2Dstore(MouseStorage, float2(DTID.x, DTID.y), 0);
		#endif
	}
}

[shader("compute")]
void CS_Draw(uint3 GTID : SV_GroupThreadID, uint3 DTID : SV_DispatchThreadID)
{
	if(bIsDrawing){
		float2 LastMousePos = tex2Dfetch(DrawingStorage, int2(0,0)).rg;
		float2 MouseDelta = MousePos - LastMousePos;
		float radn = max(1, Radius);
		float smoothenlimit = max(1,length(MouseDelta) / Radius);
		smoothenlimit *= KD_SMOOTHENING;
		for(int r = 0; r < smoothenlimit; r++){
			for(int i = DTID.x; i < radn; i++){
				for(int j = DTID.y; j < radn; j++){
					if(length(float2(i,j)) < Radius){
						int2 signs;
						signs.x = DTID.x == 0 ? -1 : 1;
						signs.y = DTID.y == 0 ? -1 : 1;
						int2 targetpos = MousePos;
						targetpos += (signs * int2(i,j));
						targetpos -= (MouseDelta * (r / smoothenlimit));
						targetpos.x = max(0, targetpos.x);
						targetpos.y = max(0, targetpos.y);
						targetpos.x = min(targetpos.x, BUFFER_WIDTH);
						targetpos.y = min(targetpos.y, BUFFER_HEIGHT);
						tex2Dstore(
							DrawingStorage, 
							targetpos, 
							BrushColor
						);
						#if KD_DEBUGMOUSE == 1
						tex2Dstore(
							MouseStorage, 
							MousePos + int2(i,j) / 2, 
							float4(0,1,0,1)
						);
						#endif
					}
				}
			}
		}
	}
	tex2Dstore(
		DrawingStorage, 
		int2(0,0), 
		float4(MousePos.x, MousePos.y, 0, 0)
	);
	// Since the texture is retained even after parameter changes
	// It's quite secure to put the old mouse position as data there
	// MouseDelta didn't work properly, so I made my own workaround
	// Scuffed? Maybe. Does it work? Yes.
}

float3 PS_ApplyDrawing(float4 SV_POSITION : SV_Position, float2 TexCoord : TEXCOORD) : SV_Target
{
	float3 ret = 0;
	
	float2 ScreenUV = UV_To_Res(TexCoord);
	
	ret = tex2D(SamplerColor, TexCoord).rgb;
	
	float4 drawingpix = tex2D(SamplerDrawing, TexCoord);
	
	ret = lerp(ret, drawingpix.rgb, drawingpix.a);
	
	#if KD_DEBUGMOUSE == 1
	float4 mousepix = tex2D(SamplerMouse, TexCoord);
	ret = lerp(ret, mousepix.rgb, mousepix.a);
	#endif
	
	if(bIsDrawing)
	{
		if(
			ScreenUV.x > MousePos.x &&
			ScreenUV.y < MousePos.y &&
			ScreenUV.x < MousePos.x + PaintbrushSize &&
			ScreenUV.y > MousePos.y - PaintbrushSize
		){
			float2 newuv = ScreenUV - MousePos;
			newuv.y += PaintbrushSize;
			newuv /= PaintbrushSize;
			float4 brush = tex2D(SamplerPaintbrush, newuv);
			
			ret = lerp(ret, brush.rgb, brush.a);
		}
	}
	
	return ret;
}

technique K_Paintbrush
{
	pass p0
	{
		ComputeShader = CS_WipeTex<32,32,1>; 
		// More threads better, in testing
		DispatchSizeX = BUFFER_WIDTH / 32;
		DispatchSizeY = BUFFER_HEIGHT / 32;
	}
	pass p1
	{
		ComputeShader = CS_Draw<0,0,0>;
		// These numbers ensure the drawing compute shader
		// only gets executed once per frame
		// and thus makes drawing virtually costless
		DispatchSizeX = 2;
		DispatchSizeY = 2;
		// Made them 2x2 for the 4 quadrants of the brush
		// teehee
		// Maybe this optimizes stuff at higher radiuses
	}
	pass p2
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_ApplyDrawing;
	}
}