#!/bin/env ruby
# With massive Credits to:
# http://www.perl.com/pub/a/2004/12/01/3d_engine.html
# Rewritten into Ruby

require "sdl"
require "opengl"
include Gl,Glu,Glut

# Done yet
$done = false

# Frames
$frame = 0

# Window information
Title = 'Test Engine'
Width = 640
Height = 480

# Sdl
$sdl_screen = nil

#-------------------------------------------
def Init()
    STDOUT.sync = true
    Init_window()
end


#-------------------------------------------
def Init_window()
    SDL.init(SDL::INIT_VIDEO)
    SDL::GL.set_attr(SDL::GL_RED_SIZE,5)
    SDL::GL.set_attr(SDL::GL_GREEN_SIZE,5)
    SDL::GL.set_attr(SDL::GL_BLUE_SIZE,5)
    SDL::GL.set_attr(SDL::GL_DEPTH_SIZE,16)
    SDL::GL.set_attr(SDL::GL_DOUBLEBUFFER,1)

    $sdl_screen = SDL::Screen.open(Width,Height,0,SDL::OPENGL)
    SDL::WM.set_caption(Title, Title)

    # Hide the Cursor
    SDL::Mouse.hide
end


#-------------------------------------------
def Main_loop()
    until($done) do
	$frame += 1
	Do_frame()
    end
end


#-------------------------------------------
def Do_frame()
    Prep_frame()
    Draw_frame()
    End_frame()
end


#-------------------------------------------
def Prep_frame()
    glClear(GL_COLOR_BUFFER_BIT)
end


#-------------------------------------------
def Draw_frame()
    print '.'
    sleep(1)
    $done = true if $frame == 5
end


#-------------------------------------------
def End_frame()
    SDL::GL.swap_buffers
end


#-------------------------------------------
def Cleanup()
    print "\nDone.\n"
end


#-------------------------------------------
Init()
Main_loop()
Cleanup()
