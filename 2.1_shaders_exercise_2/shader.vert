#version 330 core
layout (location = 0) in vec2 a_position;

uniform float x_offset;

void main() {
    gl_Position = vec4(a_position.x + x_offset, a_position.y, 0.0f, 1.0f);
}
