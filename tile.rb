#!/bin/env ruby
# This code was created by Anja Berens 2009 with credits to
#   Jeff Molofee '99
#   Manolo Padron Martinez - Ruby port

require "opengl"
include Gl,Glu,Glut

# Which type of Engine, true for hexagon based, and false for tile based
HEXAGON_TILE = true

# Direction of Hexagon rendering, true for vertical hexagon tiles, and false for horzional
HEXAGON_VERT = true

# Define step for hexagon
HEXAGON_STEP = (2.0 * Math::PI/6.0)

# Hexagon specifications
HEXAGON_SIZE = 1.0
HEXAGON_RADIUS = HEXAGON_SIZE/2
HEXAGON_HEIGHT = HEXAGON_SIZE * Math.cos(HEXAGON_STEP/2.0)
HEXAGON_SIDE = HEXAGON_SIZE * Math.sin(HEXAGON_STEP/2.0)

# Cached Sin/Cos values
$CACHE_SIN = []
$CACHE_COS = []

# Define Max map
MAP_SIZEX = 10
MAP_SIZEY = 10

# Texture
$texture=[nil, nil]

$map = [
[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
[1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
]

# Default position of the camera
$x = 0.0
$y = 0.0
$z = -5.0

# Default Rotation of the Camera
$rotx = 0.0
$roty = 0.0
$rotz = 0.0

# Define the struct image
Image=Struct.new("Image", :sizeX, :sizeY, :data)


#-----------------------------------------------------------
def Fps
    # FPS
    if ($frame.nil? or $frame >= 1000)
	puts "FPS: #{$frame / (Time.now - $start_time)}" unless $start_time.nil?

	$frame = 0
	$start_time = Time.now
    else
	$frame += 1
    end
end


#-----------------------------------------------------------
def Pregenerate_Hexagon() 
    if HEXAGON_VERT
	angle = 0.0
    else
	angle = HEXAGON_STEP * 1.5
    end

    6.times do |x|
	$CACHE_SIN << Math.cos(angle)
	$CACHE_COS << Math.sin(angle)
	angle += HEXAGON_STEP
    end
end


#-----------------------------------------------------------
def Render_Hexagon(p_x, p_y)

    if HEXAGON_VERT
	angle = 0.0

	tile_x = p_x * HEXAGON_SIDE * 1.5
	tile_y = p_y * HEXAGON_HEIGHT + (p_x % 2) * HEXAGON_HEIGHT / 2.0
    else
	# The hexagon is rotated till the final vertix is at the top, to simpfy its placement
	angle = HEXAGON_STEP * 1.5
	
	tile_x = p_x * HEXAGON_HEIGHT + (p_y % 2) * HEXAGON_HEIGHT / 2.0
	tile_y = p_y * HEXAGON_SIDE * 1.5
    end
		    
    glBegin(GL_TRIANGLE_FAN)
	glTexCoord2f(0.5, 0.5)
	glVertex3f(tile_x, tile_y, 0.0)

#	for num_vertices in (0...6) do
	6.times do |num_vertices|
#	    x = Math.cos(angle)
#	    y = Math.sin(angle)
	    x = $CACHE_SIN[num_vertices]
	    y = $CACHE_COS[num_vertices]

	    angle += HEXAGON_STEP

	    glTexCoord2f((x+1)/2.0, (y+1)/2.0)
	    glVertex3f(tile_x + HEXAGON_RADIUS * x, tile_y + HEXAGON_RADIUS * y, 0.0)
	end

	# Close the fan
	if HEXAGON_VERT
	    glTexCoord2f(1.0, 0.5)
	    glVertex3f(tile_x + HEXAGON_RADIUS, tile_y, 0.0)
	else
	    glTexCoord2f(0.5, 1.0)
	    glVertex3f(tile_x, tile_y + HEXAGON_RADIUS, 0.0)
	end
    glEnd()
end


#-----------------------------------------------------------
def Render_Square(p_x, p_y)
    glBegin(GL_QUADS)
	glTexCoord2f(0.0, 0.0)
	glVertex3f(p_x, p_y, 0.0)

	glTexCoord2f(1.0, 0.0)
	glVertex3f(p_x + 1, p_y, 0.0)

	glTexCoord2f(1.0, 1.0)
	glVertex3f(p_x + 1, p_y + 1, 0.0)

	glTexCoord2f(0.0, 1.0)
	glVertex3f(p_x, p_y + 1, 0.0)
    glEnd()
end


#-----------------------------------------------------------
# quick and dirty bitmap loader... for 24 bit bitmaps with 1 plane only.
# See http://www.dcs.ed.ac.uk/~mxr/gfx/2d/BMP.txt for more info.
def ImageLoad(filename, image)
    begin
	file=File.open(filename,"r")
	# Seek through the bmp header, up to the width/height:
	file.seek(18,IO::SEEK_CUR)

	# Read the width
	tmp=file.read(4).unpack('I').to_s.to_i
	image[:sizeX]=tmp
	if (tmp.nil?)
	    $stderr.print "Error reading Width from "+ filename +"\n"
	    return false
	end

	# Read the height
	tmp=file.read(4).unpack('I').to_s.to_i
	image[:sizeY]=tmp
	if (tmp.nil?)
	    $stderr.print "Error reading Height from "+ filename +"\n"
	    return false
	end

	# Calculate the size of the bmp assuming 3 bytes per pixel
	size=image[:sizeX]*image[:sizeY]*3

	# Read the planes
	tmp=file.read(2).unpack('s').to_s.to_i
	if (tmp!=1)
	    $stderr.print "Planes from  "+ filename +" is not 1:"+ tmp.to_s() +"\n"
	    return false
	end

	# Read the bpp
	tmp=file.read(2).unpack('s').to_s.to_i
	if (tmp!=24)
	    $stderr.print "Bpp from  "+ filename +" is not 24: "+ tmp.to_s() + "\n"
	    return false
	end

	# Seek past the rest of the bitmap header.
	file.seek(24,IO::SEEK_CUR)

	# Read the data.
	image[:data]=file.read(size)

	# Reverse all components of the colors (bgr->rgb)
	i=0
	while i+2<size
	    image[:data][i..i+2]= image[:data][i..i+2].reverse
	    i=i+3
	end

	# we're done
	true
    rescue SystemCallError
	$stderr.print "File Not Found: "+ filename + "\n"
	false
    ensure #Close the file if exists
	file.close unless file.nil?
    end
end


#-----------------------------------------------------------
def LoadGLTextures
    #load both texture
    image0 = Image.new
    image1 = Image.new
    exit(1) unless ImageLoad("tile2.bmp", image0)
    exit(1) unless ImageLoad("tile1.bmp", image1)

    # Create Texture
    $texture = glGenTextures(2)

    # Texture 0
    glBindTexture(GL_TEXTURE_2D, $texture[0])
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    
    # 2D texture, level of detail 0(normal), 3 components(red,green,blue)
    # x size from image, y size from image, border 0 (normal), rgb format,
    # format of the data, and finally the data itself
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image0[:sizeX],
		 image0[:sizeY], 0, GL_RGB,
		 GL_UNSIGNED_BYTE, image0[:data])
    
    # Texture 1
    glBindTexture(GL_TEXTURE_2D, $texture[1])
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    
    # 2D texture, level of detail 0(normal), 3 components(red,green,blue)
    # x size from image, y size from image, border 0 (normal), rgb format,
    # format of the data, and finally the data itself
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image1[:sizeX],
		 image1[:sizeY], 0, GL_RGB,
		 GL_UNSIGNED_BYTE, image1[:data])
end


#-----------------------------------------------------------
# We call this right after our OpenGL window is created.
def InitGL(width, height)
    # Load the textures
    LoadGLTextures()

    # Enable Texture mapping
    glEnable(GL_TEXTURE_2D)

    # Clear the background to black
    glClearColor(0.0, 0.0, 0.0, 0.0)

    # Enable clearing of the depth buffer
    glClearDepth(1.0)

    # Enable smoothing and color shading
    glShadeModel(GL_SMOOTH)

    # Reset the Projection Matrix
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()

    # Calculate the aspect ratio of the window
    gluPerspective(45.0,Float(width)/Float(height),0.1,100.0)

    # Reset back to the model Matrix
    glMatrixMode(GL_MODELVIEW)
	    
    if HEXAGON_TILE
	Pregenerate_Hexagon() 
    end
end


#-----------------------------------------------------------
# The function called when our window is resized
ReSizeGLScene = lambda {|width, height|
    height = 1 if height == 0

    # Resets the current Viewport and Prespective Transformation
    glViewport(0,0,width,height)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    gluPerspective(45.0,Float(width)/Float(height),0.1,100.0)
    glMatrixMode(GL_MODELVIEW)
}


#-----------------------------------------------------------
# The main drawing function. 
DrawGLScene = lambda {
    # I don't know why I have to put this in the draw event
    # this is only a problem with ruby-opengl. The original
    # program in C don't need it.
    glMatrixMode(GL_MODELVIEW)

    # Set up the Lighting
    lightAmbient=[0.5,0.5,0.5,1.0]
    #lightDiffuse=[1.0,1.0,1.0,1.0]
    #lightPosition=[0.0,0.0,2.0,1.0]
    glLightfv(GL_LIGHT0, GL_AMBIENT, lightAmbient)
    #glLightfv(GL_LIGHT0, GL_DIFFUSE, lightDiffuse)
    #glLightfv(GL_LIGHT0, GL_POSITION, lightPosition)
    glEnable(GL_LIGHT0)

    # Clear the Screen and the Depth Buffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    # Reset the view
    glLoadIdentity()

    # Move the camera to the current position as indicated by the user
    glRotate($rotx, 1, 0, 0);
    glRotate($roty, 0, 1, 0);
    glRotate($rotz, 0, 0, 1);
    glTranslate($x, $y, $z);


    # Tile rendering
#    for y in (0...MAP_SIZEY) do
    MAP_SIZEY.times do |y|
#	for x in (0...MAP_SIZEX) do
	MAP_SIZEX.times do |x|
	    tile = $map[y][x]
	    
	    glBindTexture(GL_TEXTURE_2D, $texture[tile])

	    if HEXAGON_TILE
		Render_Hexagon(x,y)
	    else
		Render_Square(x,y)
	    end
	end
    end

    Fps()

    # Since this is double buffered, swap the buffers to display 
    # what just got drawn.
    glutSwapBuffers()
}


#-----------------------------------------------------------
# The function called whenever a key is pressed.
keyPressed = lambda {|key, x, y| 
    case key
	when 27
	    # If the esc key is pressed, shutdown the window and exit
	    glutDestroyWindow($window)
	    exit(0)
    end
}


#-----------------------------------------------------------
# The function called whenever a special key is pressed
specialKeyPressed = lambda {|key,x,y|

    # Get the modifier key such as SHIFT, CTRL, ALT
    mod = glutGetModifiers()

    case key
	when GLUT_KEY_UP
	    if mod == GLUT_ACTIVE_SHIFT
		$rotx += 1
	    else
		$y -= 1
	    end
	when GLUT_KEY_DOWN
	    if mod == GLUT_ACTIVE_SHIFT
		$rotx -= 1
	    else
		$y += 1
	    end
	when GLUT_KEY_LEFT
	    if mod == GLUT_ACTIVE_SHIFT
		$roty -= 1
	    else
		$x += 1
	    end
	when GLUT_KEY_RIGHT
	    if mod == GLUT_ACTIVE_SHIFT
		$roty += 1
	    else
		$x -= 1
	    end
	when GLUT_KEY_PAGE_UP
	    if mod == GLUT_ACTIVE_SHIFT
		$rotz += 1
	    else
		$z += 1
	    end
	when GLUT_KEY_PAGE_DOWN
	    if mod == GLUT_ACTIVE_SHIFT
		$rotz -= 1
	    else
		$z -= 1
	    end
    end

    # Prints out the current position and rotation of the camera to the console
    puts "x = #{$x}, y = #{$y}, z = #{$z}"
    puts "rotx = #{$rotx}, roty = #{$roty}, rotz = #{$rotz}"
}


#-----------------------------------------------------------
#Initialize GLUT state - glut will take any command line arguments that pertain
# to it or X Windows - look at its documentation at 
# http://reality.sgi.com/mjk/spec3/spec3.html 
glutInit

#Select type of Display mode:   
# Double buffer 
# RGBA color
# Alpha components supported 
# Depth buffer 
glutInitDisplayMode(GLUT_RGBA|GLUT_DOUBLE|GLUT_ALPHA|GLUT_DEPTH)

# get a 640x480 window
glutInitWindowSize(640,480)

# the window starts at the upper left corner of the screen
glutInitWindowPosition(0,0)

# Open a window
$window=glutCreateWindow("Tiling Engine")

# Register the function to do all our OpenGL drawing.
glutDisplayFunc(DrawGLScene)

# Go fullscreen. This is as soon as possible.
#glutFullScreen()

# Even if there are no events, redraw our gl scene.
glutIdleFunc(DrawGLScene)

# Register the function called when our window is resized.
glutReshapeFunc(ReSizeGLScene)

# Register the function called when the keyboard is pressed.
glutKeyboardFunc(keyPressed)

# Register the function called when special keys 
# (arrows, pagedown, etc) are pressed.
glutSpecialFunc(specialKeyPressed)

# Initialize our window.
InitGL(640, 480)

# Start Event Processing Engine
glutMainLoop()

