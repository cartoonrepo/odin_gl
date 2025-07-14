#version 330 core
out vec4 frag_color;

in vec4 v_color;
in vec2 v_tex_coord;

uniform float     mix_value;
uniform sampler2D texture_0;
uniform sampler2D texture_1;

void main() {
    frag_color = mix(texture(texture_0, v_tex_coord), texture(texture_1, v_tex_coord), mix_value);
}
 
