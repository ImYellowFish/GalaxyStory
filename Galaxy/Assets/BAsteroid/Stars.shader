Shader "Fish/Stars"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_DarkColor ("_DarkColor", Color) = (0,0,0,0)
		_BrightColor ("_BrightColor", Color) = (1,1,1,1)
		_Seed ("_Seed", Range(0.5, 1)) = 0.659
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

			// https://www.shadertoy.com/view/MdXSzS

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			fixed4 _DarkColor;
			fixed4 _BrightColor;
			float _Seed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float2 uv = i.uv - 0.5;
				float t = frac(_Time.x / 3.1416) * 3.1416;
				float sint = sin(t);
				float cost = cos(t);
				float s = 0.0;
				float v = 0.0;
				for (int i = 0; i < 20; i++) {
					float3 p = s * float3(uv, 0.0);
					//p.x = p.x * cost + p.y * sint;
					//p.y = p.x * -sint + p.y * cost;
					p += float3(0.1, 0.2, s - 0.1 * sint);
					for (int j = 0; j < 8; j++) {
						p = abs(p) / dot(p, p) - _Seed;
					}
					v += dot(p, p) * 0.0015;
					s += 0.035;
				}

				v*=0.3;
                // sample the texture
                fixed4 col = lerp(_DarkColor, _BrightColor, v);
				return col;
            }
            ENDCG
        }
    }
}
