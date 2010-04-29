#include <GL/glut.h>    // Header File For The GLUT Library 
#include <GL/gl.h>	// Header File For The OpenGL32 Library
#include <GL/glu.h>	// Header File For The GLu32 Library
#include <unistd.h>     // needed to sleep
#include <stdlib.h>	// Needed for random number
#include <math.h>	// sqrt function
#include <stdio.h>	// printf function

/* Default position of the Camera */
float x = 0.0f;
float y = 0.0f;
float z = -5.0f;

/* Default rotation of the Camera */
float rotx = 0.0f;
float roty = 0.0f;
float rotz = 0.0f;

/* Boolean for wireframe */
int wireframe = 0;

/* subdivide stuff */
int sub_div = 2;
int max_div = 6;

/* The number of our GLUT window */
int window; 

/* Fps stuff */
int frame = 0;
int start_time = 0;

/* Vertices for the sphere thingie */
#define X .525731112119133606 
#define Z .850650808352039932

static float vdata[12][3] = {
    {-X, 0.0, Z}, {X, 0.0, Z}, {-X, 0.0, -Z}, {X, 0.0, -Z},    
    {0.0, Z, X}, {0.0, Z, -X}, {0.0, -Z, X}, {0.0, -Z, -X},    
    {Z, X, 0.0}, {-Z, X, 0.0}, {Z, -X, 0.0}, {-Z, -X, 0.0} 
};

static int tindices[20][3] = {
    {0,4,1}, {0,9,4}, {9,5,4}, {4,5,8}, {4,8,1},    
    {8,10,1}, {8,3,10}, {5,3,8}, {5,2,3}, {2,7,3},    
    {7,10,3}, {7,6,10}, {7,11,6}, {11,0,6}, {0,1,6}, 
    {6,1,10}, {9,0,11}, {9,11,2}, {9,2,5}, {7,2,11}
};

static float cdata[20][3];

#ifdef NOASM
/* Normalize function */
void normalize(float v1[4], float v2[4], float v3[4]) {
    normalize_sub(v1);
    normalize_sub(v2);
    normalize_sub(v3);
}

void normalize_sub(float v[4]) {
    GLfloat d = sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]); 
    if (d == 0.0) {
	printf("zero length vector");    
	return;
    }
    v[0] /= d; v[1] /= d; v[2] /= d; 
}
#else // SSE version
extern void normalize(float v1[4], float v2[4], float v3[4]);
#endif

/* Not used anymore, commenting out for now
void normcrossprod(float v1[3], float v2[3], float out[3]) 
{ 
    out[0] = v1[1]*v2[2] - v1[2]*v2[1]; 
    out[1] = v1[2]*v2[0] - v1[0]*v2[2]; 
    out[2] = v1[0]*v2[1] - v1[1]*v2[0]; 
    normalize(out); 
}*/

/* Draw triagles */
void drawtriangle(float *v1, float *v2, float *v3) 
{ 
    glBegin(GL_POLYGON); 
	glNormal3fv(v1);
	glVertex3fv(v1);    
	glNormal3fv(v2);
	glVertex3fv(v2);    
	glNormal3fv(v3);
	glVertex3fv(v3);    
    glEnd(); 
}

/* subdivision */
void subdivide(float *v1, float *v2, float *v3, long depth)
{
    float v12[4] __attribute__((aligned(16)));
    float v23[4] __attribute__((aligned(16)));
    float v31[4] __attribute__((aligned(16)));
    int i;

    /* Set the 4th to zero */
    v12[4] = 0.0f;
    v23[4] = 0.0f;
    v31[4] = 0.0f;

    if (depth == 0) {
	drawtriangle(v1, v2, v3);
	return;
    }
    for (i = 0; i < 3; i++) {
	v12[i] = v1[i]+v2[i];
	v23[i] = v2[i]+v3[i];
	v31[i] = v3[i]+v1[i];
    }
/*    normalize(v12);
    normalize(v23);
    normalize(v31);
*/
    normalize(v12, v23, v31);

    subdivide(v1, v12, v31, depth-1);
    subdivide(v2, v23, v12, depth-1);
    subdivide(v3, v31, v23, depth-1);
    subdivide(v12, v23, v31, depth-1);
}


/* Calculate and spit out the frame rate */
void Fps() {
    frame++;
    int time = glutGet(GLUT_ELAPSED_TIME);
    if (time - start_time > 1000) {
	printf("FPS:%4.2f\n",
		frame*1000.0/(time-start_time));
	start_time = time;		
	frame = 0;
    }
}


/* A general OpenGL initialization function.  Sets all of the initial parameters. */
void InitGL(int Width, int Height)	        // We call this right after our OpenGL window is created.
{
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);		// This Will Clear The Background Color To Black
    glClearDepth(1.0);				// Enables Clearing Of The Depth Buffer
    glShadeModel(GL_SMOOTH);			// Enables Smooth Color Shading

    glDepthFunc(GL_LESS);			        // The Type Of Depth Test To Do
    glEnable(GL_DEPTH_TEST);		        // Enables Depth Testing
    glEnable(GL_NORMALIZE);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();				// Reset The Projection Matrix

    gluPerspective(45.0f,(GLfloat)Width/(GLfloat)Height,0.1f,100.0f);	// Calculate The Aspect Ratio Of The Window

    glMatrixMode(GL_MODELVIEW);
}

/* The function called when our window is resized (which shouldn't happen, because we're fullscreen) */
void ReSizeGLScene(int Width, int Height)
{
    if (Height==0)				// Prevent A Divide By Zero If The Window Is Too Small
	Height=1;

    glViewport(0, 0, Width, Height);		// Reset The Current Viewport And Perspective Transformation

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    gluPerspective(45.0f,(GLfloat)Width/(GLfloat)Height,0.1f,100.0f);
    glMatrixMode(GL_MODELVIEW);
}

/* The main drawing function. */
void DrawGLScene()
{
    glMatrixMode(GL_MODELVIEW);

    // Lighting/etc
    GLfloat lightAmbient[4] = {0.5f, 0.5f, 0.5f, 1.0f};
    glLightfv(GL_LIGHT0, GL_AMBIENT, lightAmbient);
    glEnable(GL_LIGHT0);
    
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
    glLoadIdentity();				// Reset The View

    //  Move the camera/etc
    glTranslatef(x, y, z);

    glRotatef(rotx, 1.0f, 0.0f, 0.0f);
    glRotatef(roty, 0.0f, 1.0f, 0.0f);
    glRotatef(rotz, 0.0f, 0.0f, 1.0f);

    if (wireframe) {
	glPolygonMode(GL_FRONT, GL_LINE);
	glPolygonMode(GL_BACK, GL_LINE);
    } else {
	glPolygonMode(GL_FRONT, GL_FILL);
	glPolygonMode(GL_BACK, GL_FILL);
    }

    /* Call the display list stuff here */
    int i;
    for (i = 0; i < 20; i++) { 
	glColor3fv(cdata[i]);

	subdivide(&vdata[tindices[i][0]][0],       
		&vdata[tindices[i][1]][0],       
		&vdata[tindices[i][2]][0],
		sub_div);
    }

    /* Call the FPS stuff here */
    Fps();

    // swap the buffers to display, since double buffering is used.
    glutSwapBuffers();
}


/* Draw traigle/subdivision stuff here */


/* The function called whenever a key is pressed. */
void keyPressed(unsigned char key, int x, int y) 
{
    /* avoid thrashing this call */
    usleep(100);

    switch(key) {
	case 27:
	    /* Esc key, shutdown and exit */
	    glutDestroyWindow(window); 
	    exit(0);
	    break;

	case 32:
	    /* Space bar, toggle the color/wireframe mode */
	    if (wireframe == 0)
		wireframe = 1;
	    else
		wireframe = 0;
    }
}


/* The function called whenever a special key is pressed. */
void specialKeyPressed(int key, int x, int y)
{
    int mod = glutGetModifiers();

    switch(key) {
	case GLUT_KEY_UP:
	    if (mod == GLUT_ACTIVE_SHIFT)
		y -= 1.0f;
	    else
		rotx += 1.0f;
	    break;
	case GLUT_KEY_DOWN:
	    if (mod == GLUT_ACTIVE_SHIFT)
		y += 1.0f;
	    else
		rotx -= 1.0f;
	    break;
	case GLUT_KEY_LEFT:
	    if (mod == GLUT_ACTIVE_SHIFT)
		x += 1.0f;
	    else
		roty -= 1.0f;
	    break;
	case GLUT_KEY_RIGHT:
	    if (mod == GLUT_ACTIVE_SHIFT)
		x -= 1.0f;
	    else
		roty += 1.0f;
	    break;
	case GLUT_KEY_PAGE_UP:
	    if (mod == GLUT_ACTIVE_SHIFT)
		z += 1.0f;
	    else
		rotz += 1.0f;
	    break;
	case GLUT_KEY_PAGE_DOWN:
	    if (mod == GLUT_ACTIVE_SHIFT)
		z -= 1.0f;
	    else
		rotz -= 1.0f;
	    break;
	case GLUT_KEY_HOME:
	    if (mod == GLUT_ACTIVE_SHIFT)
		if (sub_div < max_div)
		    sub_div += 1;
	    break;
	case GLUT_KEY_END:
	    if (mod == GLUT_ACTIVE_SHIFT)
		if (sub_div > 0)
		    sub_div -= 1;
	    break;
    }
}
	

int main(int argc, char **argv) 
{  
    /* Initialize GLUT state - glut will take any command line arguments that pertain to it or 
       X Windows - look at its documentation at http://reality.sgi.com/mjk/spec3/spec3.html */  
    glutInit(&argc, argv);  

    /* Select type of Display mode:   
       Double buffer 
       RGBA color
       Alpha components supported 
       Depth buffered for automatic clipping */  
    glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_ALPHA | GLUT_DEPTH);  

    /* get a 640 x 480 window */
    glutInitWindowSize(640, 480);  

    /* the window starts at the upper left corner of the screen */
    glutInitWindowPosition(0, 0);  

    /* Open a window */  
    window = glutCreateWindow("Hexagon Sphere - C version");

    /* Register the function to do all our OpenGL drawing. */
    glutDisplayFunc(&DrawGLScene);  

    /* Go fullscreen.  This is as soon as possible. */
    //glutFullScreen();

    /* Even if there are no events, redraw our gl scene. */
    glutIdleFunc(&DrawGLScene);

    /* Register the function called when our window is resized. */
    glutReshapeFunc(&ReSizeGLScene);

    /* Register the function called when the keyboard is pressed. */
    glutKeyboardFunc(&keyPressed);
    
    /* Register the function called when the keyboard is pressed. */
    glutSpecialFunc(&specialKeyPressed);

    /* Initialize our window. */
    InitGL(640, 480);

    /* Setup the colors */
    int i;
    int j;
    for(i = 0; i < 20; i++) {
	for(j = 0; j < 3; j++) {
	    cdata[i][j] = rand()/((double)RAND_MAX + 1);
	}
    }

    /* Compile the display list */


    /* Start Event Processing Engine */  
    glutMainLoop();  

    return 1;
}
