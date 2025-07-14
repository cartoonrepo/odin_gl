// create the same 2 triangles using two different VAOs and VBOs for their data
package main

import glm "core:math/linalg/glsl"
import gl  "vendor:OpenGL"
import SDL "vendor:sdl3"

import "../utils"

TITLE         :: "1.2_triangle_exercise_2"
SCREEN_WIDTH  :: 800
SCREEN_HEIGHT :: 600

VERTEX_SOURCE   :: TITLE + "/shader.vert"
FRAGMENT_SOURCE :: TITLE + "/shader.frag"

Vertex :: struct {
    position: glm.vec2,
    color   : glm.vec4,
}

main :: proc() {
    utils.init_window(TITLE, SCREEN_WIDTH, SCREEN_HEIGHT, {.OPENGL})
    defer utils.close_window()

    SDL.GL_SetSwapInterval(1)

    shader, ok := gl.load_shaders(VERTEX_SOURCE, FRAGMENT_SOURCE); defer gl.DeleteProgram(shader)
    if !ok {
        when gl.GL_DEBUG {
            fmt.eprintln(gl.get_last_error_message())
        }
    }

    // colors for 'a_color' in vertex shader.
    warm_gold      := glm.vec4{1.0,   0.8,   0.361, 1.0}
    soft_violet    := glm.vec4{0.729, 0.408, 0.784, 1.0}
    mint_green     := glm.vec4{0.4,   1.0,   0.8,   1.0}

    vertices_1 := []Vertex {
        // first triangle
        {{-1.0, -0.5}, mint_green }, // bottom left
        {{ 0.0, -0.5}, warm_gold  }, // bottom right
        {{-0.5, 0.5 }, soft_violet}, // top
    }

    vertices_2 := []Vertex {
        // second triangle
        {{ 0.0, -0.5}, warm_gold  }, // bottom left
        {{ 1.0, -0.5}, mint_green }, // bottom right
        {{ 0.5, 0.5 }, soft_violet}, // top
    }

    // buffers
    vao, vbo: [2]u32

    gl.GenVertexArrays(2, raw_data(vao[:])); defer gl.DeleteVertexArrays(2, raw_data(vao[:]))
    gl.GenBuffers(2, raw_data(vbo[:]));      defer gl.DeleteBuffers(2, raw_data(vbo[:]))

    // first triangle
    gl.BindVertexArray(vao[0])
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo[0])
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices_1) * size_of(Vertex), raw_data(vertices_1), gl.STATIC_DRAW)
    gl.EnableVertexAttribArray(0)
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(0, i32(len(vertices_1[0].position)), gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
    gl.VertexAttribPointer(1, i32(len(vertices_1[0].color)),    gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))

    // second triangle
    gl.BindVertexArray(vao[1])
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo[1])
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices_2) * size_of(Vertex), raw_data(vertices_2), gl.STATIC_DRAW)
    gl.EnableVertexAttribArray(0)
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(0, i32(len(vertices_2[0].position)), gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
    gl.VertexAttribPointer(1, i32(len(vertices_2[0].color)),    gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))

    main_loop: for {
        if !utils.process_events() {
            break main_loop
        }

        // draw
        gl.ClearColor(0.0, 0.1, 0.15, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(shader)

        // draw first triangle
        gl.BindVertexArray(vao[0])
        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        // draw second triangle
        gl.BindVertexArray(vao[1])
        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        SDL.GL_SwapWindow(utils.window)
    }
}

