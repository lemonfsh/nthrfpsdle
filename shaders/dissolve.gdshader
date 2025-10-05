shader_type spatial;

uniform sampler2D real_texture : source_color, filter_nearest;
uniform sampler2D dissolve_texture : source_color;
uniform float dissolve_value : hint_range(0,1);
void vertex() {
	if (true){
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	}
}

void fragment(){
    vec4 main_texture = texture(real_texture, UV);
    vec4 noise_texture = texture(dissolve_texture, UV);
    main_texture.a *= floor(dissolve_value + min(1, noise_texture.x));
	vec3 real = vec3(main_texture.r, main_texture.g, main_texture.b);
	ALBEDO = real;
	ALPHA = main_texture.a;
}