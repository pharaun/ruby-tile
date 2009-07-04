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

# Camera
Fovy = 90


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

    SDL::Screen.open(Width,Height,0,SDL::OPENGL)
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
    glClear(GL_COLOR_BUFFER_BIT |
	   GL_DEPTH_BUFFER_BIT )

    glEnable(GL_DEPTH_TEST)
end


#-------------------------------------------
def Draw_frame()
    Set_projection_3d()
    Set_view_3d()
    Draw_view()

    print '.'
    sleep(1)
    $done = true if $frame == 5
end


#-------------------------------------------
def Set_projection_3d()
    aspect = Width / Height

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    gluPerspective(Fovy, aspect, 1, 1000)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
end


#-------------------------------------------
def Set_view_3d()
    # Move viewpoint so we can see the origin
    glTranslate(0, -2, -10)
end


#-------------------------------------------
def Draw_view()
    Draw_axes()

    glColor(1, 1, 1)
    glPushMatrix()
    glTranslate(0, 0, -4)
    glScale(2, 2, 2)
    Draw_cube()
    glPopMatrix()
    
    glColor(1, 1, 0)
    glPushMatrix()
    glTranslate(4, 0, 0)
    glRotate(40, 0, 0, 1)
    glScale(0.2, 1, 2)
    Draw_cube()
    glPopMatrix()
end


#-------------------------------------------
def Draw_axes()
    # Lines from origin along positive axes, for orientation
    # X axis = red, Y axis = green, Z axis = blue
    glBegin(GL_LINES);
	glColor(1, 0, 0);
	glVertex(0, 0, 0);
	glVertex(1, 0, 0);

	glColor(0, 1, 0);
	glVertex(0, 0, 0);
	glVertex(0, 1, 0);

	glColor(0, 0, 1);
	glVertex(0, 0, 0);
	glVertex(0, 0, 1);
    glEnd;

end


#-------------------------------------------
def Draw_cube()
    indices = [ 4,5,6,7,  1,2,6,5,  0,1,5,4,
		0,3,2,1,  0,4,7,3,  2,3,7,6 ]

    vertices = [[-1, -1, -1], [ 1, -1, -1],
		[ 1,  1, -1], [-1,  1, -1],
		[-1, -1,  1], [ 1, -1,  1],
		[ 1,  1,  1], [-1,  1,  1]]

    glBegin(GL_QUADS)
	6.times do |face|
	    4.times do |vertex|
		index = indices[4 * face + vertex]
		coords = vertices[index]
		
		glVertex(coords)
	    end
	end
    glEnd()

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
