#!/bin/env ruby
# With massive Credits to:
# http://www.perl.com/pub/a/2004/12/01/3d_engine.html
# Rewritten into Ruby

require "sdl"
require "opengl"
require "RMagick"
include Gl,Glu,Glut

class Engine

    # Create and setup the inistance variables
    def initialize()
	@conf = nil

	# Resources for the engine
	@resource = {
	    :sdl_app => nil
	}

	# Engine state
	@state = {
	    :done		=> false,
	    :frame		=> 0,
	    :need_screenshot	=> false,
	    :screenshot_seq	=> 0
	}

	# World's state
	@world = {
	    :time	=> 0,
	    :d_time	=> 0,
	    :view	=> nil
	}

	# Event lookup table
	@lookup = {}

	# Event/command lookup table
	@actions = {}
    end


    #-------------------------------------------
    def init()
	STDOUT.sync = true

	init_conf()
	init_window()
	init_event_processing()
	init_command_actions()
	init_view()
	init_time()
    end


    #-------------------------------------------
    def init_conf()
	@conf = {
	    :title  => 'Test Engine',
	    :width  => 640,
	    :height => 480,
	    :fovy   => 90,
	    :bind   => {
		'escape'    => :quit,
		'f4'	    => :_screenshot,
		'a'	    => :_move_left,
		'd'	    => :_move_right,
		'w'	    => :_move_forward,
		's'	    => :_move_back,
		'left'	    => :_yaw_left,
		'right'	    => :_yaw_right,
		'tab'	    => :_look_behind
	    }
	}
    end


    #-------------------------------------------
    def init_window()
	SDL.init(SDL::INIT_VIDEO)
	SDL::GL.set_attr(SDL::GL_RED_SIZE,5)
	SDL::GL.set_attr(SDL::GL_GREEN_SIZE,5)
	SDL::GL.set_attr(SDL::GL_BLUE_SIZE,5)
	SDL::GL.set_attr(SDL::GL_DEPTH_SIZE,16)
	SDL::GL.set_attr(SDL::GL_DOUBLEBUFFER,1)

	SDL::Screen.open(@conf[:width],@conf[:height],0,SDL::OPENGL)
	SDL::WM.set_caption(@conf[:title], @conf[:title])

	# Hide the Cursor
	SDL::Mouse.hide
    end


    #-------------------------------------------
    def set_projection_3d()
	aspect = @conf[:width] / @conf[:height]

	glMatrixMode(GL_PROJECTION)
	glLoadIdentity()
	gluPerspective(@conf[:fovy], aspect, 1, 1000)

	glMatrixMode(GL_MODELVIEW)
	glLoadIdentity()
    end


    #-------------------------------------------
    def end_frame()
	SDL::GL.swap_buffers

	screenshot() if @state[:need_screenshot]
    end


    #-------------------------------------------
    def main_loop()
	until(@state[:done]) do
	    @state[:frame] += 1
	    update_time()
	    do_events()
	    update_view()
	    do_frame()
	end
    end


    #-------------------------------------------
    def do_frame()
	prep_frame()
	draw_frame()
	end_frame()

	glEnable(GL_COLOR_MATERIAL)
    end


    #-------------------------------------------
    def set_world_lights
	glLight(GL_LIGHT0, GL_POSITION, 0.0, 0.0, 1.0, 0.0)

	glEnable(GL_LIGHT0)
    end


    #-------------------------------------------
    def draw_frame()
	set_projection_3d()
	set_view_3d()
	set_world_lights()
	draw_view()
    end


    #-------------------------------------------
    def init_view()
	@world[:view] = {
	    :position	    => [6, 2, 10],
	    :orientation    => [0, 0, 1, 0],
	    :d_yaw	    => 0,
	    :v_yaw	    => 0,
	    :v_forward	    => 0,
	    :v_right	    => 0,
	    :dv_yaw	    => 0,
	    :dv_forward	    => 0,
	    :dv_right	    => 0
	}
    end


    #-------------------------------------------
    def update_view()
	# yaws
	@world[:view][:orientation][0] += @world[:view][:d_yaw]
	@world[:view][:d_yaw] = 0

	@world[:view][:v_yaw] += @world[:view][:dv_yaw]
	@world[:view][:dv_yaw] = 0

	@world[:view][:orientation][0] += @world[:view][:v_yaw] * @world[:d_time]

	# Forward/backward, sidways
	@world[:view][:v_right] += @world[:view][:dv_right]
	@world[:view][:dv_right] = 0

	@world[:view][:v_forward] += @world[:view][:dv_forward]
	@world[:view][:dv_forward] = 0

	vx, vz = rotate_xz(@world[:view][:orientation][0], 
			   @world[:view][:v_right],
			   -@world[:view][:v_forward])

	@world[:view][:position][0] += vx * @world[:d_time]
	@world[:view][:position][2] += vz * @world[:d_time]
    end


    #-------------------------------------------
    def rotate_xz(angle, x, z)
	cos = Math.cos(angle * Math::PI / 180)
	sin = Math.sin(angle * Math::PI / 180)

	rot_x =	 cos * x + sin * z
	rot_z = -sin * x + cos * z

	return [rot_x, rot_z]
    end


    #-------------------------------------------
    def set_view_3d()
	angle, rx, ry, rz = @world[:view][:orientation]
	x, y, z = @world[:view][:position]

	glRotate(-angle, rx, ry, rz)
	glTranslate(-x, -y, -z)
    end


    #-------------------------------------------
    def main()
	init()
	main_loop()
	cleanup()
    end


    #-------------------------------------------
    def update_time()
	new_now = now()

	@world[:d_time] = new_now - @world[:time]
	@world[:time] = now()
    end


    #-------------------------------------------
    def now()
	return SDL::getTicks() / 1000
    end


    #-------------------------------------------
    def prep_frame()
	glClear(GL_COLOR_BUFFER_BIT |
	       GL_DEPTH_BUFFER_BIT )

	glEnable(GL_DEPTH_TEST)
    end


    #-------------------------------------------
    def draw_view()

	glDisable(GL_LIGHTING)
	draw_axes()
	glEnable(GL_LIGHTING)

	glColor(1, 1, 1)
	glPushMatrix()
	glTranslate(12, 0, -4)
	glScale(2, 2, 2)
	draw_cube()
	glPopMatrix()

	glColor(1, 1, 0)
	glPushMatrix()
	glTranslate(4, 0, 0)
	glRotate(40, 0, 0, 1)
	glScale(0.2, 1, 2)
	draw_cube()
	glPopMatrix()
    end


    #-------------------------------------------
    def draw_axes()
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
    def draw_cube()
	indices = [ 4,5,6,7,  1,2,6,5,  0,1,5,4,
		    0,3,2,1,  0,4,7,3,  2,3,7,6 ]

	vertices = [[-1, -1, -1], [ 1, -1, -1],
		    [ 1,  1, -1], [-1,  1, -1],
		    [-1, -1,  1], [ 1, -1,  1],
		    [ 1,  1,  1], [-1,  1,  1]]

	normals = [[0, 0,  1], [ 1, 0, 0], [0, -1, 0],
		   [0, 0, -1], [-1, 0, 0], [0,  1, 0]]

	glBegin(GL_QUADS)
	    6.times do |face|
		glNormal(normals[face])

		4.times do |vertex|
		    index = indices[4 * face + vertex]
		    coords = vertices[index]

		    glVertex(coords)
		end
	    end
	glEnd()

    end


    #-------------------------------------------
    def cleanup()
	print "\nDone.\n"
    end


    #-------------------------------------------
    def init_event_processing()
	# Add SDL events to be processed here
	@lookup[:quit] = method(:process_quit)
	@lookup[:keyup] = method(:process_key)
	@lookup[:keydown] = method(:process_key)
    end


    #-------------------------------------------
    def init_command_actions()
	@actions[:quit] = method(:action_quit)
	@actions[:_screenshot] = method(:action_screenshot)
	@actions[:_move_left] = method(:action_move)
	@actions[:_move_right] = method(:action_move)
	@actions[:_move_forward] = method(:action_move)
	@actions[:_move_back] = method(:action_move)
	@actions[:_yaw_left] = method(:action_move)
	@actions[:_yaw_right] = method(:action_move)
	@actions[:_look_behind] = method(:action_move)
    end


    #-------------------------------------------
    def do_events()
	queue = process_events()

	while (not @state[:quit] and not queue.empty?)
	    command = queue.pop

	    if command.kind_of?(Array)
		the_command = command.shift
		action = @actions[the_command]
		action.call(the_command, command)
	    else
		action = @actions[command] or next
		action.call()
	    end
	end
    end


    #-------------------------------------------
    def process_events()
	queue = []

	while (not @state[:quit] and event = SDL::Event.poll)
	    case event
		when SDL::Event::Quit
		    eventType = :quit

		when SDL::Event::KeyDown
		    eventType = :keydown
		
		when SDL::Event::KeyUp
		    eventType = :keyup
	    end

	    # Gets the method to call for the event or skip to next event
	    process = @lookup[eventType] or next

	    # Execute the method, and if there is more work needed, other wise
	    # if its to be ignored, it shall return a false
	    command = process.call(event, eventType)

	    queue.push(command) if command != false
	end
	return queue
    end


    #-------------------------------------------
    def process_quit(event, eventType)
	@state[:done] = true
	puts "runs"
	return :quit
    end


    #-------------------------------------------
    def process_key(event, eventType)
	name = SDL::Key.getKeyName(event.sym)

	if ((@conf[:bind][name].to_s =~ /^_.*/) != nil)
	    return ([@conf[:bind][name], eventType == :keyup] || false)
	else
	    return (@conf[:bind][name] || false)
	end
    end


    #-------------------------------------------
    def action_quit()
	@state[:done] = true
    end


    #-------------------------------------------
    def action_move(command, args)
	sign = args[0] ? 1 : -1
	speed_yaw = 36
	speed_move = 5

	move_update = {
	    :_yaw_left	    =>  [:dv_yaw,	speed_yaw],
	    :_yaw_right	    =>  [:dv_yaw,	-speed_yaw],
	    :_move_right    =>  [:dv_right,	speed_move],
	    :_move_left	    =>  [:dv_right,	-speed_move],
	    :_move_forward  =>  [:dv_forward,	speed_move],
	    :_move_back	    =>  [:dv_forward,	-speed_move],
	    :_look_behind   =>  [:d_yaw,	180]
	}

	update = move_update[command] or return

	@world[:view][update[0]] += (update[1] * sign)
    end

    
    #-------------------------------------------
    def action_screenshot(command, args)

	if not args[0]
	    @state[:need_screenshot] = true
	end
    end


    #-------------------------------------------
    def init_time()
	@world[:time] = now()
    end
    
    
    #-------------------------------------------
    def screenshot()
	file = "screenshot#{@state[:screenshot_seq]}.png"

	glReadBuffer(GL_FRONT)

	data = glReadPixels(0, 0, @conf[:width], @conf[:height],
			    GL_RGBA, GL_UNSIGNED_SHORT)

	image = Magick::Image.new(@conf[:width], @conf[:height])
	image.import_pixels(0, 0, @conf[:width], @conf[:height],
			    "RGBA", data, Magick::ShortPixel)
	image.flip!
	image.write(file)

	@state[:screenshot_seq] += 1
	@state[:need_screenshot] = false
    end
end


e = Engine.new
e.main()
