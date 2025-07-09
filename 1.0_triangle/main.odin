// check out https://learnopengl.com/Getting-started/Hello-Triangle

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

PATH            :: "1.0_triangle/"
VERTEX_SOURCE   :: PATH + "shader.vert"
FRAGMENT_SOURCE :: PATH + "shader.frag"

Vertex :: struct {
    position: glm.vec2,
    color   : glm.vec4,
}

main :: proc() {
    // https://pkg.odin-lang.org/vendor/sdl3/#WindowFlag
    // flags := SDL.WindowFlags { .OPENGL, .RESIZABLE }
    init_window("Cartoon Window", SCREEN_WIDTH, SCREEN_HEIGHT, {.OPENGL})
    defer close_window()

    // vsync
    SDL.GL_SetSwapInterval(1)

    // https://pkg.odin-lang.org/vendor/OpenGL/#load_shaders
    shader, ok := gl.load_shaders(VERTEX_SOURCE, FRAGMENT_SOURCE)
    if !ok {
        // https://pkg.odin-lang.org/vendor/OpenGL/#get_last_error_message
        // https://github.com/odin-lang/Odin/blob/090cac62f9cc30f759cba086298b4bdb8c7c62b3/vendor/OpenGL/helpers.odin#L51

        // in release mode compiler will print shader error by default.
        // that's why i added debug check so error print happens one time.
        when gl.GL_DEBUG {
            fmt.eprintln("SHADER ERROR:\n", gl.get_last_error_message())
        }
    }

    // colors for 'a_color' in vertex shader.
    tomato_red     := glm.vec4{1.0,   0.388, 0.278, 1.0}
    warm_gold      := glm.vec4{1.0,   0.8,   0.361, 1.0}
    soft_violet    := glm.vec4{0.729, 0.408, 0.784, 1.0}
    mint_green     := glm.vec4{0.4,   1.0,   0.8,   1.0}

    // vertices for hungry gpu.
    vertices := []Vertex {
        {{-0.5, -0.5}, mint_green },
        {{ 0.5, -0.5}, warm_gold  },
        {{ 0.0,  0.5}, soft_violet},
    }

    // buffers
    vao, vbo: u32

    gl.GenVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo)

    gl.BindVertexArray(vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0) // a_positon in vertex shader
    gl.EnableVertexAttribArray(1) // a_color   in vertex shader

    // Vertex position is vec2: number of components = 2
    // Vertex color    is vec4: number of components = 4
    gl.VertexAttribPointer(0, i32(len(vertices[0].position)), gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
    gl.VertexAttribPointer(1, i32(len(vertices[0].color)),    gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))

    // in odin offset pointer is uintptr
    // https://pkg.odin-lang.org/vendor/OpenGL/#VertexAttribPointer
    // 0 * size_of(f32)                   or uintptr(0 * size_of(vertices[0].position[0]))  = 0
    // 2 * size_of(vertices[0].color[0])  or uintprt(2 * size_of(vertices[0].color[0]))     = 8
    // gl.VertexAttribPointer(0, i32(len(vertices[0].position)), gl.FLOAT, false, size_of(Vertex), uintptr(0 * size_of(f32)))
    // gl.VertexAttribPointer(1, i32(len(vertices[0].color)),    gl.FLOAT, false, size_of(Vertex), 2 * size_of(vertices[0].color[0]))

    for !should_exit {
        process_events()

        // draw
        gl.ClearColor(0.0, 0.1, 0.15, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(shader)
        gl.BindVertexArray(vao)
        gl.DrawArrays(gl.TRIANGLES, 0, i32(len(vertices)))

        SDL.GL_SwapWindow(window)
    }
}

process_events :: proc() {
    for SDL.PollEvent(&event) {
        // https://pkg.odin-lang.org/vendor/sdl3/#EventType
        #partial switch event.type {
        case .QUIT:
            should_exit = true

        case .WINDOW_PIXEL_SIZE_CHANGED:
            // https://wiki.libsdl.org/SDL3/SDL_Event
            // see  SDL_WindowEvent
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

    // set opengl core profile and version 3.3
    // https://pkg.odin-lang.org/vendor/sdl3/#GLAttr
    // https://pkg.odin-lang.org/vendor/sdl3/#GLProfile
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

    // https://pkg.odin-lang.org/vendor/OpenGL/#load_up_to
    // https://pkg.odin-lang.org/vendor/sdl3/#gl_set_proc_address
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
