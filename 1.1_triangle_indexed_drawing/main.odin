package main

import glm "core:math/linalg/glsl"
import gl  "vendor:OpenGL"
import SDL "vendor:sdl3"

import "../utils"

TITLE         :: "1.1_triangle_indexed_drawing"
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

    // vsync
    SDL.GL_SetSwapInterval(1)

    shader, ok := gl.load_shaders(VERTEX_SOURCE, FRAGMENT_SOURCE); defer gl.DeleteProgram(shader)
    if !ok {
        when gl.GL_DEBUG {
            fmt.eprintln(gl.get_last_error_message())
        }
    }

    // colors for 'a_color' in vertex shader.
    tomato_red     := glm.vec4{1.0,   0.388, 0.278, 1.0}
    warm_gold      := glm.vec4{1.0,   0.8,   0.361, 1.0}
    soft_violet    := glm.vec4{0.729, 0.408, 0.784, 1.0}
    mint_green     := glm.vec4{0.4,   1.0,   0.8,   1.0}

    // vertices for hungry gpu.
    vertices := []Vertex {
        //a_position   a_color    in vertex shader  
        {{-0.5,  0.5}, mint_green }, // top    left 
        {{ 0.5,  0.5}, warm_gold  }, // top    right
        {{ 0.5, -0.5}, soft_violet}, // bottom right
        {{-0.5, -0.5}, tomato_red }, // bottom left 
    }
    //                 first  |  second   triangle
    indices := []u16 { 0, 1, 2, 2, 3, 0 }

    // buffers
    vao, vbo, ebo: u32

    gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo);      defer gl.DeleteBuffers(1, &vbo)
    gl.GenBuffers(1, &ebo);      defer gl.DeleteBuffers(1, &ebo)

    gl.BindVertexArray(vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(indices[0]), raw_data(indices), gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0) // a_positon in vertex shader
    gl.EnableVertexAttribArray(1) // a_color   in vertex shader

    gl.VertexAttribPointer(0, i32(len(vertices[0].position)), gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
    gl.VertexAttribPointer(1, i32(len(vertices[0].color)),    gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))

    gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

    main_loop: for {
        if !utils.process_events() {
            break main_loop
        }

        // draw
        gl.ClearColor(0.0, 0.1, 0.15, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(shader)
        gl.BindVertexArray(vao)

        // !NOTE: change to UNSIGNED_INT if you are using u32 for indices.
        gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)

        SDL.GL_SwapWindow(utils.window)
    }
}

