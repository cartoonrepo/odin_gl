package main

import      "core:fmt"
import      "core:os"
import      "core:time"
import glm  "core:math/linalg/glsl"
import gl   "vendor:OpenGL"
import SDL  "vendor:sdl3"
import stbi "vendor:stb/image"

TITLE         :: "3.1_textures"
SCREEN_WIDTH  :: 800
SCREEN_HEIGHT :: 600

GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3

VERTEX_SOURCE   :: TITLE + "/shader.vert"
FRAGMENT_SOURCE :: TITLE + "/shader.frag"

TEXTURE_SOURCE_1 :: "./resources/textures/1.png"
TEXTURE_SOURCE_2 :: "./resources/textures/2.png"

Vertex :: struct {
    position  : glm.vec2,
    color     : glm.vec4,
    tex_coord : glm.vec2,
}

window     : ^SDL.Window
gl_context :  SDL.GLContext
event      :  SDL.Event

main :: proc() {
    init_window(TITLE, SCREEN_WIDTH, SCREEN_HEIGHT, {.OPENGL})
    defer close_window()

    // vsync
    SDL.GL_SetSwapInterval(1)

    shader, ok := gl.load_shaders(VERTEX_SOURCE, FRAGMENT_SOURCE)
    defer gl.DeleteProgram(shader)
    if !ok {
        when gl.GL_DEBUG {
            fmt.eprintln("SHADER ERROR:\n", gl.get_last_error_message())
        }
    }

    vertices := []Vertex {
        {{-0.5,  0.5}, {1.0, 0.0, 0.0, 1.0}, {0.0, 1.0}}, // top    left 
        {{ 0.5,  0.5}, {0.0, 1.0, 0.0, 1.0}, {1.0, 1.0}}, // top    right
        {{ 0.5, -0.5}, {0.0, 0.0, 1.0, 1.0}, {1.0, 0.0}}, // bottom right
        {{-0.5, -0.5}, {1.0, 1.0, 0.0, 1.0}, {0.0, 0.0}}, // bottom left 
    }

    indices := []u16 {0, 1, 2, 2, 3, 0}

    vao, vbo, ebo: u32

    gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo);      defer gl.DeleteBuffers(1, &vbo)
    gl.GenBuffers(1, &ebo);      defer gl.DeleteBuffers(1, &ebo)

    gl.BindVertexArray(vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(indices[0]), raw_data(indices), gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0) // a_positon
    gl.EnableVertexAttribArray(1) // a_color
    gl.EnableVertexAttribArray(2) // a_tex_coord

    gl.VertexAttribPointer(0, i32(len(vertices[0].position)),  gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
    gl.VertexAttribPointer(1, i32(len(vertices[0].color)),     gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))
    gl.VertexAttribPointer(2, i32(len(vertices[0].tex_coord)), gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, tex_coord))

    stbi.set_flip_vertically_on_load(1)
    texture: [2]u32
    gl.GenTextures(2, raw_data(texture[:])); defer gl.DeleteTextures(2, raw_data(texture[:]))
    load_texture(&texture[0], TEXTURE_SOURCE_1, gl.RGBA, gl.RGBA)
    load_texture(&texture[1], TEXTURE_SOURCE_2, gl.RGBA, gl.RGBA)

    gl.UseProgram(shader)
    gl.Uniform1i(gl.GetUniformLocation(shader, "texture_0"), 0)
    gl.Uniform1i(gl.GetUniformLocation(shader, "texture_1"), 1)
    
    mix_value : f32
    key_state := SDL.GetKeyboardState(nil)
    
    main_loop: for {
        // press w, s to mix between two textures.
        if key_state[i32(SDL.Scancode.W)] {
            mix_value += 0.1
        }
        if key_state[i32(SDL.Scancode.S)] {
            mix_value -= 0.1
        }

        if mix_value > 1 { mix_value = 1}
        if mix_value < 0 { mix_value = 0}

        if !process_events() {
            break main_loop
        }

        // draw
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, texture[0])
        gl.ActiveTexture(gl.TEXTURE1)
        gl.BindTexture(gl.TEXTURE_2D, texture[1])

        gl.Uniform1f(gl.GetUniformLocation(shader, "mix_value"), mix_value)

        gl.BindVertexArray(vao)
        gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)

        SDL.GL_SwapWindow(window)
    }
}

load_texture :: proc(texture: ^u32, source: cstring, internalformat: i32, format: u32) {
    gl.BindTexture(gl.TEXTURE_2D, texture^)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    w, h, channels: i32
    data := stbi.load(source, &w, &h, &channels, 0)
    if data != nil {
        gl.TexImage2D(gl.TEXTURE_2D, 0, internalformat, w, h, 0, format, gl.UNSIGNED_BYTE, data)
        gl.GenerateMipmap(gl.TEXTURE_2D)
    } else {
        fmt.println("Failed to load texture.")
    }
    stbi.image_free(data)
}

process_events :: proc() -> bool {
    for SDL.PollEvent(&event) {
        #partial switch event.type {
        case .QUIT:
            return false

        case .WINDOW_PIXEL_SIZE_CHANGED:
            w := event.window.data1
            h := event.window.data2
            gl.Viewport(0, 0, w, h)

        case .KEY_DOWN:
            #partial switch event.key.scancode {
            case .ESCAPE:
                return false
            }
        }
    }
    return true
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

