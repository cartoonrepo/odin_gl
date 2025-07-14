// Specify a horizontal offset via a uniform and move the triangle to the right side of the screen in the vertex shader using this offset value.

package main

import     "core:time"
import glm "core:math/linalg/glsl"
import gl  "vendor:OpenGL"
import SDL "vendor:sdl3"

import "../utils"

TITLE         :: "2.1_shaders_exercise_2"
SCREEN_WIDTH  :: 800
SCREEN_HEIGHT :: 600

VERTEX_SOURCE   :: TITLE + "/shader.vert"
FRAGMENT_SOURCE :: TITLE + "/shader.frag"

Vertex :: struct {
    position: glm.vec2,
}

main :: proc() {
    utils.init_window(TITLE, SCREEN_WIDTH, SCREEN_HEIGHT, {.OPENGL})
    defer utils.close_window()

    // vsync
    SDL.GL_SetSwapInterval(1)

    shader, ok := gl.load_shaders(VERTEX_SOURCE, FRAGMENT_SOURCE); defer gl.DeleteProgram(shader)
    if !ok {
        when gl.GL_DEBUG {
            fmt.eprintln(gl.get_last_error_message())
        }
    }

    // vertices for hungry gpu.
    vertices := []Vertex {
        {{-0.5, -0.5}}, // bottom left
        {{ 0.5, -0.5}}, // bottom right
        {{ 0.0,  0.5}}, // top
    }

    // buffers
    vao, vbo: u32

    gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo);      defer gl.DeleteBuffers(1, &vbo)

    gl.BindVertexArray(vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0) // a_positon in vertex shader
    gl.VertexAttribPointer(0, i32(len(vertices[0].position)), gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))

    start_tick := time.tick_now()

    main_loop: for {
        duration := time.tick_since(start_tick)
        t := f32(time.duration_seconds(duration))

        if !utils.process_events() {
            break main_loop
        }

        // draw
        gl.ClearColor(0.0, 0.1, 0.15, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(shader)

        red   := glm.sin(t) / 2 + 0.5
        green := glm.cos(t) / 4 + 0.5
        blue  := glm.sin(t) / 6 + 0.5

        gl.Uniform4f(gl.GetUniformLocation(shader, "our_color"), red, green, blue, 1.0)
        gl.Uniform1f(gl.GetUniformLocation(shader, "x_offset"),  glm.sin(t))

        gl.BindVertexArray(vao)
        gl.DrawArrays(gl.TRIANGLES, 0, i32(len(vertices)))

        SDL.GL_SwapWindow(utils.window)
    }
}

