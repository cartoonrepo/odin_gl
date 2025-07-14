// Create two shader programs where the second program uses a different fragment shader that outputs the color yellow;
// draw both triangles again where one outputs the color yellow

package main

import glm "core:math/linalg/glsl"
import gl  "vendor:OpenGL"
import SDL "vendor:sdl3"

import "../utils"

TITLE         :: "1.2_triangle_exercise_3"
SCREEN_WIDTH  :: 800
SCREEN_HEIGHT :: 600

VERTEX_SOURCE     :: TITLE + "/shader.vert"
FRAGMENT_SOURCE_1 :: TITLE + "/shader_1.frag"
FRAGMENT_SOURCE_2 :: TITLE + "/shader_2.frag"

Vertex :: struct {
    position: glm.vec2,
}

main :: proc() {
    utils.init_window(TITLE, SCREEN_WIDTH, SCREEN_HEIGHT, {.OPENGL})
    defer utils.close_window()

    SDL.GL_SetSwapInterval(1)

    ok : bool
    shader_1, shader_2 : u32

    shader_1, ok = gl.load_shaders(VERTEX_SOURCE, FRAGMENT_SOURCE_1); defer gl.DeleteProgram(shader_1)
    if !ok {
        when gl.GL_DEBUG {
            fmt.eprintln(gl.get_last_error_message())
        }
    }

    shader_2, ok = gl.load_shaders(VERTEX_SOURCE, FRAGMENT_SOURCE_2); defer gl.DeleteProgram(shader_2)
    if !ok {
        when gl.GL_DEBUG {
            fmt.eprintln(gl.get_last_error_message())
        }
    }

    vertices := []Vertex {
        // first triangle
        {{-1.0, -0.5}}, // bottom left
        {{ 0.0, -0.5}}, // bottom right
        {{-0.5, 0.5 }}, // top

        // second triangle
        {{ 0.0, -0.5}}, // bottom left
        {{ 1.0, -0.5}}, // bottom right
        {{ 0.5, 0.5 }}, // top
    }

    // buffers
    vao, vbo: [2]u32

    gl.GenVertexArrays(2, raw_data(vao[:])); defer gl.DeleteVertexArrays(2, raw_data(vao[:]))
    gl.GenBuffers(2, raw_data(vbo[:]));      defer gl.DeleteBuffers(2, raw_data(vbo[:]))

    gl.BindVertexArray(vao[0])
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo[0])
    gl.BufferData(gl.ARRAY_BUFFER, 3 * size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, i32(len(vertices[0].position)), gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))

    gl.BindVertexArray(vao[1])
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo[1])
    gl.BufferData(gl.ARRAY_BUFFER, 3 * size_of(vertices[0]), raw_data(vertices[3:]), gl.STATIC_DRAW)
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, i32(len(vertices[0].position)), gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))

    main_loop: for {
        if !utils.process_events() {
            break main_loop
        }
        // draw
        gl.ClearColor(0.0, 0.1, 0.15, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)


        // draw first triangle
        gl.UseProgram(shader_1)
        gl.BindVertexArray(vao[0])
        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        // draw second triangle
        gl.UseProgram(shader_2)
        gl.BindVertexArray(vao[1])
        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        SDL.GL_SwapWindow(utils.window)
    }
}

