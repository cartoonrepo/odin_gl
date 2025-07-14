package main

import glm "core:math/linalg/glsl"
import gl  "vendor:OpenGL"
import SDL "vendor:sdl3"

import "../utils"

TITLE         :: "1.0_triangle"
SCREEN_WIDTH  :: 800
SCREEN_HEIGHT :: 600

VERTEX_SOURCE   :: TITLE + "/shader.vert"
FRAGMENT_SOURCE :: TITLE + "/shader.frag"

Vertex :: struct {
    position: glm.vec2,
    color   : glm.vec4,
}

main :: proc() {
    // https://pkg.odin-lang.org/vendor/sdl3/#WindowFlag
    // flags := SDL.WindowFlags { .OPENGL, .RESIZABLE }
    utils.init_window(TITLE, SCREEN_WIDTH, SCREEN_HEIGHT, {.OPENGL})
    defer utils.close_window()

    // vsync
    SDL.GL_SetSwapInterval(1)

    // https://pkg.odin-lang.org/vendor/OpenGL/#load_shaders
    
    shader, ok := gl.load_shaders(VERTEX_SOURCE, FRAGMENT_SOURCE); defer gl.DeleteProgram(shader)
    if !ok {
        when gl.GL_DEBUG {
            // https://pkg.odin-lang.org/vendor/OpenGL/#get_last_error_message
            // https://github.com/odin-lang/Odin/blob/090cac62f9cc30f759cba086298b4bdb8c7c62b3/vendor/OpenGL/helpers.odin#L51
            fmt.eprintln(gl.get_last_error_message())
        }
    }

    // colors for 'a_color' in vertex shader.
    warm_gold      := glm.vec4{1.0,   0.8,   0.361, 1.0}
    soft_violet    := glm.vec4{0.729, 0.408, 0.784, 1.0}
    mint_green     := glm.vec4{0.4,   1.0,   0.8,   1.0}

    // vertices for hungry gpu.
    vertices := []Vertex {
        {{-0.5, -0.5}, mint_green }, // bottom left
        {{ 0.5, -0.5}, warm_gold  }, // bottom right
        {{ 0.0,  0.5}, soft_violet}, // top
    }

    // buffers
    vao, vbo: u32

    gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo);      defer gl.DeleteBuffers(1, &vbo)

    gl.BindVertexArray(vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0) // a_positon in vertex shader
    gl.EnableVertexAttribArray(1) // a_color   in vertex shader

    // Vertex position is vec2: number of components = 2
    // Vertex color    is vec4: number of components = 4
    gl.VertexAttribPointer(0, i32(len(vertices[0].position)), gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
    gl.VertexAttribPointer(1, i32(len(vertices[0].color)),    gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))

    // gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

    main_loop: for {
        if !utils.process_events() {
            break main_loop
        }
        // draw
        gl.ClearColor(0.0, 0.1, 0.15, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(shader)
        gl.BindVertexArray(vao)
        gl.DrawArrays(gl.TRIANGLES, 0, i32(len(vertices)))

        SDL.GL_SwapWindow(utils.window)
    }
}
