#version 330 core
out vec4 frag_color;

in vec4 v_color;
in vec2 v_tex_coord;

uniform sampler2D our_texture;

void main() {
    frag_color = texture(our_texture, v_tex_coord);
    // let's get a little funky
    // frag_color = texture(our_texture, v_tex_coord) * v_color;
}
 
