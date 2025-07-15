#version 330 core
layout (location = 0) in vec2 a_position;
layout (location = 1) in vec4 a_color;
layout (location = 2) in vec2 a_tex_coord;

out vec4 v_color;
out vec2 v_tex_coord;

uniform mat4 transform;

void main() {
    gl_Position = transform * vec4(a_position, 0.0f, 1.0f);
    v_color     = a_color;
    v_tex_coord = a_tex_coord;
}
