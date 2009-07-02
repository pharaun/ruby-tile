#!/bin/env ruby
# This code was created by Jeff Molofee '99 
# Conversion to Ruby by Manolo Padron Martinez (manolopm@cip.es)

require "opengl"
include Gl,Glu,Glut

# Which type of Engine
HEXAGON_TILE = true

# Direction of Hexagon rendering
HEXAGON_VERT = false

# Define step for hexagon
HEX_STEP = (2.0 * Math::PI/6.0)

# Hexagon specifications
HEX_SIZE = 1.0
HEX_RADIUS = HEX_SIZE/2
HEX_HEIGHT = HEX_SIZE * Math.cos(HEX_STEP/2.0)
HEX_SIDE = HEX_SIZE * Math.sin(HEX_STEP/2.0)

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

#Define the struct image
Image=Struct.new("Image", :sizeX, :sizeY, :data)


#-----------------------------------------------------------
def Fps
    # FPS
    if ($frame.nil? or $frame >= 1000)
	if ($start_time.nil?)
	    $frame = 0
	    $start_time = Time.now
	else
	    puts "FPS: #{$frame / (Time.now - $start_time)}"
	    $frame = 0
	    $start_time = Time.now
	end
    else
	$frame += 1
    end
end


#-----------------------------------------------------------
def Render_Hexagon(p_x, p_y)

    if HEXAGON_VERT
	angle = 0.0
	tile_x = p_x * HEX_SIDE * 1.5
	tile_y = p_y * HEX_HEIGHT + (p_x % 2) * HEX_HEIGHT / 2.0
    else
	angle = HEX_STEP * 1.5
	tile_x = p_x * HEX_HEIGHT + (p_y % 2) * HEX_HEIGHT / 2.0
	tile_y = p_y * HEX_SIDE * 1.5
    end
		    
    glBegin(GL_TRIANGLE_FAN)
	glTexCoord2f(0.5, 0.5)
	#glVertex3f(0.0, 0.0, 0.0)
	glVertex3f(tile_x, tile_y, 0.0)

	for num_vertices in (0...6) do
	    x = Math.cos(angle)
	    y = Math.sin(angle)

	    angle += HEX_STEP

	    glTexCoord2f((x+1)/2.0, (y+1)/2.0)
	    #glVertex3f(HEX_RADIUS * x, HEX_RADIUS * y, 0.0)
	    glVertex3f(tile_x + HEX_RADIUS * x, tile_y + HEX_RADIUS * y, 0.0)
	end

	if HEXAGON_VERT
	    # Close the fan
	    glTexCoord2f(1.0, 0.5)
	    #glVertex3f(HEX_RADIUS, 0.0, 0.0)
	    glVertex3f(tile_x + HEX_RADIUS, tile_y, 0.0)
	else
	    # Close the fan
	    glTexCoord2f(0.5, 1.0)
	    #glVertex3f(HEX_RADIUS, 0.0, 0.0)
	    glVertex3f(tile_x, tile_y + HEX_RADIUS, 0.0)
	end
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
    # The ruby-opengl don't have yet GenTextures like in the standard
    # The solution is 2 calls to GenTextures by the moment.
    $texture = glGenTextures(2)

    # Texture 0
    glBindTexture(GL_TEXTURE_2D, $texture[0])
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    
    # 2D texture, level of detail 0(normal, 3 components(red,green,blue)
    # x size from image, y size from image, border 0 (normal), rgb format,
    # format of the data, and finally the data itself
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image0[:sizeX],
		 image0[:sizeY], 0, GL_RGB,
		 GL_UNSIGNED_BYTE, image0[:data])
    
    # Texture 1
    glBindTexture(GL_TEXTURE_2D, $texture[1])
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    
    # 2D texture, level of detail 0(normal, 3 components(red,green,blue)
    # x size from image, y size from image, border 0 (normal), rgb format,
    # format of the data, and finally the data itself
    glTexImage2D(GL_TEXTURE_2D, 0, 3, image1[:sizeX],
		 image1[:sizeY], 0, GL_RGB,
		 GL_UNSIGNED_BYTE, image1[:data])
end


#-----------------------------------------------------------

def InitGL(width, height) # We call this right after our OpenGL window 
			    # is created.
    LoadGLTextures()                  # Load the texture(s)
    glEnable(GL_TEXTURE_2D)          # Enable texture mapping
    glClearColor(0.0, 0.0, 0.0, 0.0) # This Will Clear The Background 
    # Color To Black
    glClearDepth(1.0)                # Enables Clearing Of The Depth Buffer

    glShadeModel(GL_SMOOTH)         # Enables Smooth Color Shading
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()                 # Reset The Projection Matrix
    gluPerspective(45.0,Float(width)/Float(height),0.1,100.0) # Calculate The 
    # Aspect Ratio 
    # Of The Window
    glMatrixMode(GL_MODELVIEW)

    #Setup blending
    #glBlendFunc(GL_SRC_ALPHA,GL_ONE) #Set the blending Function for translucency
    #glEnable(GL_BLEND)
end


#-----------------------------------------------------------

# The function called when our window is resized (which shouldn't happen, 
# because we're fullscreen) 
ReSizeGLScene = lambda {|width, height|
    if (height==0) # Prevent A Divide By Zero If The Window Is Too Small
	height=1
    end
    glViewport(0,0,width,height) # Reset The Current Viewport And
    # Perspective Transformation
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
    lightAmbient=[0.5,0.5,0.5,1.0]
    #lightDiffuse=[1.0,1.0,1.0,1.0]
    #lightPosition=[0.0,0.0,2.0,1.0]
    glLightfv(GL_LIGHT0, GL_AMBIENT, lightAmbient)
    #glLightfv(GL_LIGHT0, GL_DIFFUSE, lightDiffuse)
    #glLightfv(GL_LIGHT0, GL_POSITION, lightPosition)
    glEnable(GL_LIGHT0)

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT) # Clear The Screen And
    # The Depth Buffer
    glLoadIdentity()                       # Reset The View

    glRotate($rotx, 1, 0, 0);
    glRotate($roty, 0, 1, 0);
    glRotate($rotz, 0, 0, 1);
    glTranslate($x, $y, $z);


    # Tile rendering
    for y in (0...MAP_SIZEY) do
	for x in (0...MAP_SIZEX) do
	    tile = $map[y][x]
	    
	    glBindTexture(GL_TEXTURE_2D, $texture[tile])

	    if HEXAGON_TILE
		# Hexagon Tile itself
		Render_Hexagon(x,y)
	    else
		# Square Tile itself
		glBegin(GL_QUADS)
		    glTexCoord2f(0.0, 0.0)
		    glVertex3f(x, y, 0.0)
		    
		    glTexCoord2f(1.0, 0.0)
		    glVertex3f(x + 1, y, 0.0)
		    
		    glTexCoord2f(1.0, 1.0)
		    glVertex3f(x + 1, y + 1, 0.0)
		    
		    glTexCoord2f(0.0, 1.0)
		    glVertex3f(x, y + 1, 0.0)
		glEnd()
	    end
	end
    end

#    Fps()

    # Since this is double buffered, swap the buffers to display 
    # what just got drawn.
    glutSwapBuffers()
}


#-----------------------------------------------------------

# The function called whenever a key is pressed.
keyPressed = lambda {|key, x, y| 

  case key
  when 27  # If escape is pressed, kill everything. 
    glutDestroyWindow($window)     # shut down our window 
    # exit the program...normal termination.
    exit(0)                   
  end
}


#-----------------------------------------------------------

$x = 0.0
$y = 0.0
$z = -5.0

$rotx = 0.0
$roty = 0.0
$rotz = 0.0

# The function called whenever a special key is pressed
specialKeyPressed = lambda {|key,x,y|
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

