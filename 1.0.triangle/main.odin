package main

import     "core:fmt"
import     "core:os"
import     "core:math/linalg/glsl"
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

main :: proc() {
    // https://pkg.odin-lang.org/vendor/sdl3/#WindowFlag
    // flags := SDL.WindowFlags { .OPENGL, .RESIZABLE }
    init_window("Cartoon Window", SCREEN_WIDTH, SCREEN_HEIGHT, {.OPENGL})
    defer close_window()

    // vsync
    SDL.GL_SetSwapInterval(1)

    for !should_exit {
        process_events()

        // draw
        gl.ClearColor(0.0, 0.1, 0.15, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

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
