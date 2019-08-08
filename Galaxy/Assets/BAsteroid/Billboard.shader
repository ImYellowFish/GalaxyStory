Shader "Fish/MyBillboard"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BillboardY ("billboard Y factor", Range(0, 1)) = 1
		_ScaleX ("Scale X", Float) = 1
		_ScaleY ("Scale Y", Float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			float _BillboardY;
			float _ScaleX;
			float _ScaleY;

			v2f vert (appdata v)
			{
				v2f o;
				//-----------------------
				// Simple billboard
				//-----------------------
				//float3 center = UnityObjectToViewPos(float4(0,0,0,1));
				//o.vertex = UnityViewToClipPos(float4(center.x + i.vertex.x * _ScaleX, center.y + i.vertex.y * _ScaleY, center.z, 1));
				//o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				//-----------------------
				// Complex billboard
				//-----------------------
				float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;
				objSpaceCameraPos.y = _BillboardY * objSpaceCameraPos.y;
				objSpaceCameraPos = normalize(objSpaceCameraPos);

				float3 upVector = abs(objSpaceCameraPos.y) < 0.999 ? float3(0, 1, 0) : float3(0, 0, 1);
				float3 rightVector = normalize(cross(objSpaceCameraPos, upVector));
				upVector = cross(rightVector, objSpaceCameraPos);
				float3 bd_local_vertex = rightVector * v.vertex.x * _ScaleX + upVector * v.vertex.y * _ScaleY;
				//bd_local_vertex.z = v.vertex.z;
				o.vertex = UnityObjectToClipPos(float4(bd_local_vertex, 1.0));
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				return col;
			}
			ENDCG
		}
	}
}
