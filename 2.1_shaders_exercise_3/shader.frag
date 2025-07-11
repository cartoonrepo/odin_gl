#version 330 core
out vec4 frag_color;

in vec2 v_position;

void main() {
    frag_color = vec4(v_position, 0.0f, 1.0f);
}
 
