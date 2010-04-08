#!/bin/env ruby
# Hexagon Sphere, this code is an inital proof of concept of creating a hexagon sphere

require "opengl"
include Gl,Glu,Glut

# Default position of the camera
$x = 0.0
$y = 0.0
$z = -5.0

# Default Rotation of the Camera
$rotx = 0.0
$roty = 0.0
$rotz = 0.0

# Vertices
X = 0.525731112119133606 
Z = 0.850650808352039932

Vdata = [
    [-X, 0.0, Z], [X, 0.0, Z], [-X, 0.0, -Z], [X, 0.0, -Z],    
    [0.0, Z, X], [0.0, Z, -X], [0.0, -Z, X], [0.0, -Z, -X],    
    [Z, X, 0.0], [-Z, X, 0.0], [Z, -X, 0.0], [-Z, -X, 0.0]
]

Tindices = [
    [0,4,1], [0,9,4], [9,5,4], [4,5,8], [4,8,1],    
    [8,10,1], [8,3,10], [5,3,8], [5,2,3], [2,7,3],    
    [7,10,3], [7,6,10], [7,11,6], [11,0,6], [0,1,6], 
    [6,1,10], [9,0,11], [9,11,2], [9,2,5], [7,2,11]
]

Cdata = [
    [rand, rand, rand], [rand, rand, rand], [rand, rand, rand], [rand, rand, rand],
    [rand, rand, rand], [rand, rand, rand], [rand, rand, rand], [rand, rand, rand],
    [rand, rand, rand], [rand, rand, rand], [rand, rand, rand], [rand, rand, rand],
    [rand, rand, rand], [rand, rand, rand], [rand, rand, rand], [rand, rand, rand],
    [rand, rand, rand], [rand, rand, rand], [rand, rand, rand], [rand, rand, rand]
]

# Counter for the polygons
$count = 19

#subdivide
$div = 2

# Color/wireframe
$wireframe = true

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
# We call this right after our OpenGL window is created.
def InitGL(width, height)
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

    # Prep stuff
    glEnable(GL_DEPTH_TEST)
    glEnable(GL_NORMALIZE)

    # Reset the view
    glLoadIdentity()

    # Move the camera to the current position as indicated by the user
    glTranslate($x, $y, $z);

    glRotate($rotx, 1, 0, 0);
    glRotate($roty, 0, 1, 0);
    glRotate($rotz, 0, 0, 1);

    if $wireframe
	glPolygonMode(GL_FRONT, GL_LINE)
	glPolygonMode(GL_BACK, GL_LINE)
    else
	glPolygonMode(GL_FRONT, GL_FILL)
	glPolygonMode(GL_BACK, GL_FILL)
    end

    # Rendering Code goes here
    0.upto($count) do |i|
	# Establish the Normals
#	d1 = Array.new
#	d2 = Array.new
#	
#	3.times do |j|
#	    d1.push(Vdata[Tindices[i][0]][j] - Vdata[Tindices[i][1]][j])
#	    d2.push(Vdata[Tindices[i][1]][j] - Vdata[Tindices[i][2]][j])
#	end
#
#	normal = normcrossprod(d1, d2)
#	glNormal(normal)

	glColor(Cdata[i])

#	glBegin(GL_TRIANGLES)
#	    glVertex(Vdata[Tindices[i][0]])
#	    glVertex(Vdata[Tindices[i][1]])
#	    glVertex(Vdata[Tindices[i][2]])
#	glEnd()
	subdivide(Vdata[Tindices[i][0]],
		  Vdata[Tindices[i][1]],
		  Vdata[Tindices[i][2]], $div)
    end

    # Fps
    Fps()

    # Since this is double buffered, swap the buffers to display 
    # what just got drawn.
    glutSwapBuffers()
}

#-----------------------------------------------------------
def drawtriagle(v1, v2, v3)
    glBegin(GL_TRIANGLES)
	glNormal(v1)
	glVertex(v1)
	glNormal(v2)
	glVertex(v2)
	glNormal(v3)
	glVertex(v3)
    glEnd()
end

#-----------------------------------------------------------
def subdivide(v1, v2, v3, depth)

    if depth == 0
	drawtriagle(v1, v2, v3)
	return
    end

    v12 = Array.new
    v23 = Array.new
    v31 = Array.new

    3.times do |i|
	v12.push(v1[i] + v2[i])
	v23.push(v2[i] + v3[i])
	v31.push(v3[i] + v1[i])
    end

    v12 = normalize(v12)
    v23 = normalize(v23)
    v31 = normalize(v31)

#    drawtriagle(v1, v12, v31)
#    drawtriagle(v2, v23, v12)
#    drawtriagle(v3, v31, v23)
#    drawtriagle(v12, v23, v31)
    subdivide(v1, v12, v31, depth - 1)
    subdivide(v2, v23, v12, depth - 1)
    subdivide(v3, v31, v23, depth - 1)
    subdivide(v12, v23, v31, depth - 1)
end


#-----------------------------------------------------------
def normcrossprod(v1, v2) 
    norm = Array.new

    norm.push(v1[1]*v2[2] - v1[2]*v2[1])
    norm.push(v1[2]*v2[0] - v1[0]*v2[2])
    norm.push(v1[0]*v2[1] - v1[1]*v2[0])

    return normalize(norm)
end

def normalize(v)
    norm = Array.new

    d = Math.sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2])
    if (d == 0.0)
	puts "Zero length vector"
	return v
    end

    norm.push(v[0]/d)
    norm.push(v[1]/d)
    norm.push(v[2]/d)

    return norm
end


#-----------------------------------------------------------
# The function called whenever a key is pressed.
keyPressed = lambda {|key, x, y| 
    case key
	when 27
	    # If the esc key is pressed, shutdown the window and exit
	    glutDestroyWindow($window)
	    exit(0)

	when 32
	    # Toggle the coloring/wireframe mode
	    if $wireframe
		$wireframe = false
	    else
		$wireframe = true
	    end
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
		$y -= 1
	    else
		$rotx += 1
	    end
	when GLUT_KEY_DOWN
	    if mod == GLUT_ACTIVE_SHIFT
		$y += 1
	    else
		$rotx -= 1
	    end
	when GLUT_KEY_LEFT
	    if mod == GLUT_ACTIVE_SHIFT
		$x += 1
	    else
		$roty -= 1
	    end
	when GLUT_KEY_RIGHT
	    if mod == GLUT_ACTIVE_SHIFT
		$x -= 1
	    else
		$roty += 1
	    end
	when GLUT_KEY_PAGE_UP
	    if mod == GLUT_ACTIVE_SHIFT
		$z += 1
	    else
		$rotz += 1
	    end
	when GLUT_KEY_PAGE_DOWN
	    if mod == GLUT_ACTIVE_SHIFT
		$z -= 1
	    else
		$rotz -= 1
	    end

	when GLUT_KEY_HOME
	    if mod == GLUT_ACTIVE_SHIFT
		if $div < 4
		    $div += 1
		end
	    else
		if $count < 19
		    $count += 1
		end
	    end

	when GLUT_KEY_END
	    if mod == GLUT_ACTIVE_SHIFT
		if $div > 0
		    $div -= 1
		end
	    else
		if $count > 0
		    $count -= 1
		end
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
$window=glutCreateWindow("Hexagon Sphere")

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
