shader_type spatial;
render_mode depth_draw_always, cull_back;

// TEXTURE SETTINGS
group_uniforms StandardMaterial;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

group_uniforms CameraFade;
uniform float fade_start_dist : hint_range(0.1, 10.0, 0.1) = 1.5;
uniform float fade_end_dist : hint_range(0.0, 5.0, 0.05) = 0.2;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 tex_color = texture(texture_albedo, UV);
	ALBEDO = tex_color.rgb * albedo_color.rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;

	float dist = distance(CAMERA_POSITION_WORLD, world_pos);

	float fade_alpha = smoothstep(fade_end_dist, fade_start_dist, dist);

	ALPHA = tex_color.a * albedo_color.a * fade_alpha;
}