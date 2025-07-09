#version 330 core

out vec4 frag_color;

// color from vertex shader
in vec4 v_color;

void main() {
    frag_color = v_color;
}
