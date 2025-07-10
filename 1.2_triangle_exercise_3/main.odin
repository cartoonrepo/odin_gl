package main

import     "core:fmt"
import     "core:os"
import glm "core:math/linalg/glsl"
import gl  "vendor:OpenGL"
import SDL "vendor:sdl3"

SCREEN_WIDTH  :: 800
SCREEN_HEIGHT :: 600

GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3

window     : ^SDL.Window
gl_context :  SDL.GLContext
event      :  SDL.Event

should_exit : bool

PATH              :: "./resources/shaders/"
VERTEX_SOURCE     :: PATH + "triangle.vert"
FRAGMENT_SOURCE   :: PATH + "triangle.frag"
FRAGMENT_SOURCE_1 :: PATH + "triangle_1.frag"

Vertex :: struct {
    position: glm.vec2,
    color   : glm.vec4,
}

main :: proc() {
    init_window("Cartoon Window", SCREEN_WIDTH, SCREEN_HEIGHT, {.OPENGL})
    defer close_window()

    SDL.GL_SetSwapInterval(1)

    shader, shader_1 : u32
    ok : bool
    shader, ok = gl.load_shaders(VERTEX_SOURCE, FRAGMENT_SOURCE)
    if !ok {
        when gl.GL_DEBUG {
            fmt.eprintln("SHADER ERROR:\n", gl.get_last_error_message())
        }
    }

    shader_1, ok = gl.load_shaders(VERTEX_SOURCE, FRAGMENT_SOURCE_1)
    if !ok {
        when gl.GL_DEBUG {
            fmt.eprintln("SHADER ERROR:\n", gl.get_last_error_message())
        }
    }

    // colors for 'a_color' in vertex shader.
    tomato_red     := glm.vec4{1.0,   0.388, 0.278, 1.0}
    warm_gold      := glm.vec4{1.0,   0.8,   0.361, 1.0}
    soft_violet    := glm.vec4{0.729, 0.408, 0.784, 1.0}
    mint_green     := glm.vec4{0.4,   1.0,   0.8,   1.0}

    vertices := []Vertex {
        // first triangle
        {{-1.0, -0.5}, mint_green }, // bottom left
        {{ 0.0, -0.5}, warm_gold  }, // bottom right
        {{-0.5, 0.5 }, soft_violet}, // top

        // second triangle
        {{ 0.0, -0.5}, warm_gold  }, // bottom left
        {{ 1.0, -0.5}, soft_violet}, // bottom right
        {{ 0.5, 0.5 }, mint_green }, // top
    }

    // buffers
    vao, vbo: [2]u32

    gl.GenVertexArrays(2, raw_data(vao[:]))
    gl.GenBuffers(2, raw_data(vbo[:]))

    gl.BindVertexArray(vao[0])
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo[0])
    gl.BufferData(gl.ARRAY_BUFFER, 3 * size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)
    gl.EnableVertexAttribArray(0)
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(0, i32(len(vertices[0].position)), gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
    gl.VertexAttribPointer(1, i32(len(vertices[0].color)),    gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))

    gl.BindVertexArray(vao[1])
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo[1])
    gl.BufferData(gl.ARRAY_BUFFER, 3 * size_of(vertices[0]), raw_data(vertices[3:]), gl.STATIC_DRAW)
    gl.EnableVertexAttribArray(0)
    // gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(0, i32(len(vertices[0].position)), gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
    // gl.VertexAttribPointer(1, i32(len(vertices[0].color)),    gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))



     for {
        process_events()
        if should_exit { break }

        // draw
        gl.ClearColor(0.0, 0.1, 0.15, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)


        // draw first triangle
        gl.UseProgram(shader)
        gl.BindVertexArray(vao[0])
        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        // draw second triangle
        gl.UseProgram(shader_1)
        gl.BindVertexArray(vao[1])
        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        SDL.GL_SwapWindow(window)
    }
}

process_events :: proc() {
    for SDL.PollEvent(&event) {
        #partial switch event.type {
        case .QUIT:
            should_exit = true

        case .WINDOW_PIXEL_SIZE_CHANGED:
            w := event.window.data1
            h := event.window.data2
            gl.Viewport(0, 0, w, h)

        case .KEY_DOWN:
            #partial switch event.key.scancode {
            case .ESCAPE:
                should_exit = true
            }
        }
    }
}

init_window :: proc(title: cstring, width, height: i32, flags: SDL.WindowFlags) {
    if !SDL.Init({.VIDEO}) {
        fmt.eprintfln("Couldn't initialize SDL: %v", SDL.GetError())
        os.exit(1)
    }

    SDL.GL_SetAttribute(.CONTEXT_PROFILE_MASK,  i32(SDL.GL_CONTEXT_PROFILE_CORE))
    SDL.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_MAJOR_VERSION)
    SDL.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_MINOR_VERSION)

    window = SDL.CreateWindow(title, width, height, flags)
    if window == nil {
        fmt.eprintfln("Couldn't create window: %v", SDL.GetError())
        os.exit(1)
    }

    gl_context = SDL.GL_CreateContext(window)
    if gl_context == nil {
        fmt.eprintfln("Couldn't create OpenGL context: %v", SDL.GetError())
        os.exit(1)
    }

    gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, SDL.gl_set_proc_address)

    fmt.println("VENDOR   :", gl.GetString(gl.VENDOR))
    fmt.println("RENDERER :", gl.GetString(gl.RENDERER))
    fmt.println("VERSION  :", gl.GetString(gl.VERSION))
    fmt.println("GLSL     :", gl.GetString(gl.SHADING_LANGUAGE_VERSION))

    w, h: i32
    SDL.GetWindowSizeInPixels(window, &w, &h)
    gl.Viewport(0, 0, w, h)
}

close_window :: proc() {
    SDL.GL_DestroyContext(gl_context)
    SDL.DestroyWindow(window)
}
