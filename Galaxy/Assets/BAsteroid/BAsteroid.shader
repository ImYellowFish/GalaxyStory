Shader "Fish/BAsteroid"
{
	Properties
	{
		// _MainTex ("Texture", 2D) = "white" {}
		// _Seed ("Seed", Range(0, 100)) = 1
		_ScaleX ("ScaleX", Range(0, 20)) = 1
		_ScaleY ("ScaleY", Range(0, 20)) = 1
		_NoiseScale ("NoiseScale", Range(0, 5)) = 1
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "ShaderRandom.cginc"

			// -----------------------------------
			// Variables
			// -----------------------------------

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 right : TEXCOORD1;
				float3 up : TEXCOORD2;
				float3 forward : TEXCOORD3;
			};

			// sampler2D _MainTex;
			// float4 _MainTex_ST;

			float _ScaleX;
			float _ScaleY;
			float _NoiseScale;


			// -----------------------------------
			// Geometry helpers
			// -----------------------------------

			// h: distance in z axis
			// d: distance in xy plane
			float4 get_xyhd(float2 xy, float r) {
				float d2 = dot(xy, xy);
				float d = sqrt(d2);
				float h = sqrt(abs(r * r - d2));
				return float4(xy, h, d);
			}

			float3 get_sphere_normal(float3 xyh) {
				return normalize(xyh);
			}

			float3 get_sphere_normal(float2 xy, float h) {
				return normalize(float3(xy, h));
			}

			fixed4 gamma_to_linear(fixed4 color) {
				return color * color * sign(color);
			}

			// Need variable: coord_c
			#define LOCAL_TO_VIEW_COORD(v2f_data, coord) \
				coord.x * v2f_data.right + coord.y * v2f_data.up + coord.z * v2f_data.forward

			// -----------------------------------
			// Main operations
			// -----------------------------------

			// Check if back point is culled by sphere
			// Update new back point position
			void get_back_cull_info(inout float3 coord_back_p, float3 coord_c, float r_cull, out float is_culled) {
				float3 dist_vec_to_cull = coord_back_p - coord_c;
				float dist2_to_cull = dot(dist_vec_to_cull, dist_vec_to_cull);
				is_culled = step(dist2_to_cull, r_cull * r_cull);

				float hor_dist2_to_cull = dot(dist_vec_to_cull.xy, dist_vec_to_cull.xy);
				float delta_h = sqrt(abs(r_cull * r_cull - hor_dist2_to_cull));
				coord_back_p.z = lerp(coord_back_p.z, coord_c.z + delta_h, is_culled);
			}

			// Check if front point is culled by sphere
			// Update new front point position and normal
			void get_front_cull_info(inout float3 coord_p, float3 coord_c, float r_cull, out float is_culled, inout float3 normal) {
				float3 dist_vec_to_cull = coord_p - coord_c;
				float dist2_to_cull = dot(dist_vec_to_cull, dist_vec_to_cull);
				is_culled = step(dist2_to_cull, r_cull * r_cull);

				float hor_dist2_to_cull = dot(dist_vec_to_cull.xy, dist_vec_to_cull.xy);
					float delta_h = sqrt(abs(r_cull * r_cull - hor_dist2_to_cull));
				coord_p.z = lerp(coord_p.z, coord_c.z - delta_h, is_culled);

				normal = lerp(normal, normalize(coord_c - coord_p), is_culled);
			}

			// Calculate initial point coordinate & normal,
			// declare required variables
			#define CULL_INIT(uv) \
				float3 coord_p = get_xyhd(uv, r).xyz;\
				float3 coord_back_p = float3(coord_p.xy, -coord_p.z);\
				float3 normal = get_sphere_normal(coord_p.xyz);\
				float is_front_culled, is_back_culled;\
				float3 coord_c

			// Need variable: coord_p, coord_back_p, normal, coord_c, is_front_culled, is_back_culled
			#define CULL_SPHERE(v2f_data, xyz_cull, r_cull) \
				coord_c = LOCAL_TO_VIEW_COORD(v2f_data, xyz_cull);\
				get_front_cull_info(coord_p, coord_c, r_cull, is_front_culled, normal);\
				get_back_cull_info(coord_back_p, coord_c, r_cull, is_back_culled);\
				clip(0.5 - min(is_front_culled, is_back_culled))

			
			// -----------------------------------
			// vert & frag
			// -----------------------------------

			v2f vert(appdata v)
			{
				v2f o;
				// handle billboard
				float3 sphere_center = UnityObjectToViewPos(float4(0.0, 0.0 ,0.0 ,1.0));
				float3 view_vertex_pos = sphere_center + float3(v.vertex.x * _ScaleX, v.vertex.y * _ScaleY, v.vertex.z + dot(sphere_center.xy, v.vertex.xy) * 0.25);
				o.vertex = UnityViewToClipPos(view_vertex_pos);
				// texture coordinates
				o.uv.xy = v.uv;
				// local position coordinate relative to sphere center
				o.uv.zw = v.uv - 0.5;
				// handle local coordinates
				o.right = mul((float3x3)UNITY_MATRIX_V, mul((float3x3)unity_ObjectToWorld, float3(1.0, 0.0, 0.0)));
				o.up = mul((float3x3)UNITY_MATRIX_V, mul((float3x3)unity_ObjectToWorld, float3(0.0, 1.0, 0.0)));
				o.forward = mul((float3x3)UNITY_MATRIX_V, mul((float3x3)unity_ObjectToWorld, float3(0.0, 0.0, 1.0)));
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// sqr distance to center
				float r = 0.5;
				float d2 = dot(i.uv.zw, i.uv.zw);
				clip(r * r - d2);
				
				float seed = 1;

				CULL_INIT(i.uv.zw);
				[unroll]
				for (float iter = 1.0; iter < 45.0; iter++) {
					float dr = get_white_noise(iter * 4.211 + seed * 0.235);
					float3 xyz_cull = get_random_point_on_sphere(iter * 7.1341, seed, r + dr);
					float r_cull = lerp(0.5, 1, get_white_noise(iter * 0.21 + seed * 0.5)) * (0.25 + dr);
					CULL_SPHERE(i, xyz_cull, r_cull);
				}

				float3 worldPos = float3(dot(coord_p, i.right), dot(coord_p, i.up), dot(coord_p, i.forward));
				/*normal.x += _NoiseScale * (get_perlin_noise_3d(worldPos + seed, 0.02) - 0.5);
				normal.y += _NoiseScale * (get_perlin_noise_3d(worldPos * 2.3 + seed, 0.02) - 0.5);*/
				normal.z += _NoiseScale * (get_perlin_noise_3d(worldPos * 4.1 + seed, 0.02) - 0.5);
				normal = normalize(normal);

				return dot(normal, float3(-0.3, 0.2, 0.4)) + 0.2;
				return gamma_to_linear(fixed4(normal.xyz, 0));
			}
			ENDCG
		}
	}
}
