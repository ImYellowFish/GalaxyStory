// Upgrade NOTE: unity_Scale shader variable was removed; replaced 'unity_Scale.w' with '1.0'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#include "../CGInclude/Include.cginc"

sampler2D thrusterTexture;
float4    thrusterColour;
float     thrusterGlow;

#ifdef VARIANT_FALLOFF
float thrusterFalloff;
#endif

struct V2F
{
	float4 pos : SV_POSITION;
	float2 uv0 : TEXCOORD0;
	float4 col : COLOR0;
#ifdef VARIANT_FALLOFF
	float alpha : COLOR1;
#endif
};

void Vert(A2V i, out V2F o)
{
#ifdef VARIANT_FALLOFF
	float4 vertM        = mul(unity_ObjectToWorld, i.vertex);
	float3 cam2vertM    = _WorldSpaceCameraPos - vertM.xyz;
	float3 cam2vertMDir = normalize(cam2vertM);
	float3 normalM      = mul((float3x3)unity_ObjectToWorld, i.normal);
#endif
	
	o.pos = UnityObjectToClipPos(i.vertex);
	o.uv0 = i.texcoord.xy;
	o.col = i.color;
	
#ifdef VARIANT_FALLOFF
	o.alpha = 1.0f - pow(1.0f - abs(dot(cam2vertMDir, normalM * 1.0)), thrusterFalloff);
#endif
}

void Frag(V2F i, out half4 o : COLOR)
{
	float4 thruster = tex2D(thrusterTexture, i.uv0);
	
	o = thruster * thrusterColour * i.col + thruster * thrusterGlow;
#ifdef VARIANT_FALLOFF
	o *= i.alpha;
#endif
}