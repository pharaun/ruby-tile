INCLUDE = -I/usr/include/
LIBDIR  = -L/usr/X11R6/lib 

COMPILERFLAGS = -Wall
CC = gcc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

OBJECTS = sphere.o
EXECUTABLE = sphere

all: $(OBJECTS)
	$(CC) $(CFLAGS) -o $(EXECUTABLE) $(LIBDIR) $< $(LIBRARIES)

%.o: %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(OBJECTS) $(EXECUTABLE)
