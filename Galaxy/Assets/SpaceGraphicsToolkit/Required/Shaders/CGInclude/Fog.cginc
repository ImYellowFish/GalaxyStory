// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#include "../../CGInclude/Include.cginc"

float4 fogColour;

struct V2F
{
	float4 pos : SV_POSITION;
};

void Vert(A2V i, out V2F o)
{
	o.pos = UnityObjectToClipPos(i.vertex);
}

void Frag(V2F i, out half4 o : COLOR)
{
	o = fogColour;
}