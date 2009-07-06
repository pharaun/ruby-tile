#!/bin/env ruby
# With massive Credits to:
# http://www.perl.com/pub/a/2004/12/01/3d_engine.html
# Rewritten into Ruby

require "sdl"
require "opengl"
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
	    :done	=> false,
	    :frame	=> 0
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
    end


    #-------------------------------------------
    def draw_frame()
	set_projection_3d()
	set_view_3d()
	draw_view()
    end


    #-------------------------------------------
    def init_view()
	@world[:view] = {
	    :position	    => [6, 2, 10],
	    :orientation    => [0, 0, 1, 0],
	    :d_yaw	    => 0,
	    :v_yaw	    => 0,
	    :dv_yaw	    => 0
	}
    end


    #-------------------------------------------
    def update_view()
	@world[:view][:orientation][0] += @world[:view][:d_yaw]
	@world[:view][:d_yaw] = 0

	@world[:view][:v_yaw] += @world[:view][:dv_yaw]
	@world[:view][:dv_yaw] = 0

	@world[:view][:orientation][0] += @world[:view][:v_yaw] * @world[:d_time]
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
	draw_axes()

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

	move_update = {
	    :_yaw_left	    =>  [:dv_yaw, speed_yaw],
	    :_yaw_right	    =>  [:dv_yaw, -speed_yaw],
	    :_look_behind   =>  [:d_yaw,  180]
	}

	update = move_update[command] or return

	@world[:view][update[0]] += (update[1] * sign)
    end


    #-------------------------------------------
    def init_time()
	@world[:time] = now()
    end
end


e = Engine.new
e.main()
