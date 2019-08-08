// -----------------------------------
// Noise generators
// -----------------------------------
half get_white_noise(float t) {
	return frac(21236.112 * sin(t) + 11.11);
}

float get_white_noise(float2 xy) {
	return frac(43758.5453123 * sin(12.9898 * xy.x + 78.233 * xy.y + 1.1) + 21.1231);
}

float get_white_noise(float3 xyz) {
	return frac(21236.112 * sin(10.5712 * xyz.x + 31.13823 * xyz.y + 7.3315 * xyz.z) + 21.1231);
}

float3 get_random_point_on_sphere_band(float t, float delta_seed, float rmin, float rband) {
	float3 vec = float3(get_white_noise(t + delta_seed * 1.379), get_white_noise(t + delta_seed * 13.3), get_white_noise(t + delta_seed * 46.7)) * 2.0 - 1.0;
	return normalize(vec) * (rmin + get_white_noise(t + delta_seed * 4.95) * rband);
}

float3 get_random_point_on_sphere(float t, float delta_seed, float rmin) {
	float3 vec = float3(get_white_noise(t + delta_seed * 1.379), get_white_noise(t + delta_seed * 13.3), get_white_noise(t + delta_seed * 46.7)) * 2.0 - 1.0;
	return normalize(vec) * rmin;
}

float get_perlin_noise(float2 xy, float d) {
	float2 grid = xy / d;
	float2 nxy = floor(grid.xy);
	float2 dxy = grid - nxy;

	float noise00 = get_white_noise(nxy);
	float noise10 = get_white_noise(nxy + float2(1, 0));
	float noise11 = get_white_noise(nxy + float2(1,	1));
	float noise01 = get_white_noise(nxy + float2(0, 1));

	return lerp(lerp(noise00, noise10, dxy.x), lerp(noise01, noise11, dxy.x), dxy.y);
}

float get_perlin_noise_3d(float3 xyz, float d) {
	float3 grid = xyz / d;
	float3 nxyz = floor(grid.xyz);
	float3 dxyz = grid - nxyz;

	float noises000 = get_white_noise(nxyz);
	float noises100 = get_white_noise(nxyz + float3(1, 0, 0));
	float noises010 = get_white_noise(nxyz + float3(0, 1, 0));
	float noises110 = get_white_noise(nxyz + float3(1, 1, 0));
	float noises001 = get_white_noise(nxyz + float3(0, 0, 1));
	float noises101 = get_white_noise(nxyz + float3(1, 0, 1));
	float noises011 = get_white_noise(nxyz + float3(0, 1, 1));
	float noises111 = get_white_noise(nxyz + float3(1, 1, 1));

	float noise_z0 = lerp(lerp(noises000, noises100, dxyz.x), lerp(noises010, noises110, dxyz.x), dxyz.y);
	float noise_z1 = lerp(lerp(noises001, noises101, dxyz.x), lerp(noises011, noises111, dxyz.x), dxyz.y);
	return lerp(noise_z0, noise_z1, dxyz.z);
}
