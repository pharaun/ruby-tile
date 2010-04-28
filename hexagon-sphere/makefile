INCLUDE = -I/usr/include/
LIBDIR  = -L/usr/X11R6/lib

COMPILERFLAGS = -Wall -mmmx -msse -msse2 -msse3
CC = gcc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm

ASM = yasm
ASMFLAGS = -f elf64 -a x86 -m amd64 -r raw -p gas

OBJECTS = sphere.o norm.o
EXECUTABLE = sphere

all: $(OBJECTS)
	$(CC) $(CFLAGS) -o $(EXECUTABLE) $(LIBDIR) $(OBJECTS) $(LIBRARIES)

%.o: %.c
	$(CC) $(CFLAGS) -c $<

%.o: %.asm
	$(ASM) $(ASMFLAGS) $<

clean:
	rm -f $(OBJECTS) $(EXECUTABLE)
