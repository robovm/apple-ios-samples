/*
     File: GLTextureAtlasViewController.m
 Abstract: The GLTextureAtlasViewController class is a GLKViewController subclass that renders OpenGL scene. It demonstrates how to bind a texture atlas once, and draw multiple objects with different textures using one draw call.
  Version: 1.6
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */


#import "GLTextureAtlasViewController.h"
#import "PVRTexture.h"

#define USE_4_BIT_PVR		0 //if 0 use 2-bit pvr

#define kAnimationSpeed		0.2 // (0, 1], the bigger the faster

#define NUM_COLS			4
#define NUM_ROWS			4

#define NUM_IMPOSTERS		40

#define CLAMP(min,x,max) (x < min ? min : (x > max ? max : x))
#define DegreeToRadian(x) ((x) * M_PI / 180.0f)

// get random float in [-1,1]
static inline float randf() { return (rand() % RAND_MAX) / (float)(RAND_MAX) * 2. - 1.; }

typedef struct particle {
	float x, y, z, t, v, tx, ty, tz;
	int c;
} particle;

particle butterflies[NUM_IMPOSTERS];


@interface GLTextureAtlasViewController ()
{
	GLint widthScaleIndex, frameCount; //to simulate the fly effect
	
	GLuint textureAtlas;
	PVRTexture *pvrTextureAtlas;
	
	Boolean init;
}

@property (strong, nonatomic) EAGLContext *context;

@end


@implementation GLTextureAtlasViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    
    [EAGLContext setCurrentContext:self.context];
    
    // load the texture atlas in the PVRTC format
    if (USE_4_BIT_PVR)
        [self loadPVRTexture:@"butterfly_4"];
    else //use 2-bit pvr
        [self loadPVRTexture:@"butterfly_2"];
    
    // precalc some random normals and velocities
    int i;
    for (i = 0; i < NUM_IMPOSTERS; i++) {
        float x = randf();
        float y = randf();
        float z = randf();
        if (fabs(x<0.1) && fabs(y<0.1)) {
            x += (x>0) ? 0.1 : -0.1;
            y += (y>0) ? 0.1 : -0.1;
        }
        float m = 1.0/sqrtf( (x*x) + (y*y) + (z*z) );
        butterflies[i].x = x*m;
        butterflies[i].y = y*m;
        butterflies[i].z = z*m;
        butterflies[i].t = 0;
        butterflies[i].v = randf()/2.; butterflies[i].v += (butterflies[i].v > 0) ? 0.1 : -0.1;
        butterflies[i].c = i % (NUM_ROWS*NUM_COLS);
    }
    
    // enable GL states
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

- (void)loadPVRTexture:(NSString *)name
{
	glGenTextures(1, &textureAtlas);
	glBindTexture(GL_TEXTURE_2D, textureAtlas);
	
	// setup texture parameters
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	pvrTextureAtlas = [PVRTexture pvrTextureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"pvr"]];
	[pvrTextureAtlas retain];
	
	if (pvrTextureAtlas == nil)
		NSLog(@"Failed to load %@.pvr", name);
	
	glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
	
	// release the texture atlas
	if (textureAtlas) {
		glDeleteTextures(1, &textureAtlas);
		textureAtlas = 0;
	}
	[pvrTextureAtlas release];
	pvrTextureAtlas = nil;
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
    
    [super dealloc];
}


#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
	GLfloat fov = 60.0f, zNear = 0.1f, zFar = 1000.0f, aspect = 1.5f;
	GLfloat ymax = zNear * tanf(fov * M_PI / 360.0f);
	GLfloat ymin = -ymax;
	glFrustumf(ymin * aspect, ymax * aspect, ymin, ymax, zNear, zFar);
	
    glMatrixMode(GL_MODELVIEW);
}

int comp(const void *p1, const void *p2)
{
	float d = ((particle *)p1)->tz - ((particle *)p2)->tz;
	if (d < 0) return -1;
	if (d > 0) return 1;
	return (int)p1 - (int)p2;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	GLint i = 0, j;
	static GLfloat s = 1, sz = 1;
	static GLfloat sanim = 0.001, szanim = 0.002;
	static GLfloat widthScale[8] = { 1, 0.8, 0.6, 0.4, 0.2, 0.1, 0.6, 0.8 };
    
	static GLfloat tex[NUM_COLS*NUM_ROWS][8];
	static GLushort indices_all[NUM_IMPOSTERS*6];
	
	
	glClearColor(0.7f, 0.9f, 0.6f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

	if (!init)
	{
		// compute texture coordinates of each cell
		for (i = 0; i < NUM_COLS*NUM_ROWS; i++)
		{
			GLint row = i / NUM_COLS; //y
			GLint col = i % NUM_COLS; //x
            
			GLfloat left, right, top, bottom;
			left	= col		* (1./NUM_COLS);
			right	= (col+1)	* (1./NUM_COLS);
			top		= row		* (1./NUM_ROWS);
			bottom	= (row+1)	* (1./NUM_ROWS);
            
			// the order of the texture coordinates is:
			//{left, bottom, right, bottom, left, top, right, top}
			tex[i][0] = tex[i][4] = left;
			tex[i][2] = tex[i][6] = right;
			tex[i][5] = tex[i][7] = top;
			tex[i][1] = tex[i][3] = bottom;
		}
        
		// build the index array
		for (i = 0; i < NUM_IMPOSTERS; i++)
		{
			// the first and last additional indices are added to create degenerated triangles
			// between consistent quads. for example, we use the compact index array 0123*34*4567
			// to draw quad 0123 and 4567 using one draw call
			indices_all[i*6] = i*4;
			for (j=0; j<4; j++)
				indices_all[i*6+j+1] = i*4+j;
			indices_all[i*6+5] = i*4+3;
		}
		
		init = YES;
	}

	// SW transform point to find z order
	for (i = 0; i < NUM_IMPOSTERS; i++)
	{
		float ax = DegreeToRadian(butterflies[i].x*butterflies[i].t);
		float ay = DegreeToRadian(butterflies[i].y*butterflies[i].t);
		float az = DegreeToRadian(butterflies[i].z*butterflies[i].t);
		float cosx = cosf(ax), sinx = sinf(ax);
		float cosy = cosf(ay), siny = sinf(ay);
		float cosz = cosf(az), sinz = sinf(az);
		float p1 = (sinz * butterflies[i].y + cosz * butterflies[i].x);
		float p2 = (cosy * butterflies[i].z + siny * p1);
		float p3 = (cosz * butterflies[i].y  - sinz * butterflies[i].x);
		butterflies[i].tx = cosy * p1 - siny * butterflies[i].z;
		butterflies[i].ty = sinx * p2 + cosx * p3;
		butterflies[i].tz = cosx * p2 - sinx * p3;
	}
	qsort(butterflies, NUM_IMPOSTERS, sizeof(particle), comp);
	
	// the interleaved array including position and texture coordinate data of all vertices
	// first position (3 floats) then tex coord (2 floats)
	// NOTE: we want every attribute to be 4-byte left aligned for best performance,
	// so if you use shorts (2 bytes), padding may be needed to achieve that.
	static GLfloat pos_tex_all[NUM_IMPOSTERS*4*(3+2)];
	
	// now update the interleaved data array
	for (i = 0; i < NUM_IMPOSTERS; i++)
	{
		// in order to batch the drawcalls into a single one,
		// we have to drop usage of glMatrix/glTranslate/glRotate/glScale,
		// and do the transformations ourselves.
		
		// rotation around z
		GLfloat rotzDegree = butterflies[i].z * butterflies[i].t;
		if (rotzDegree >= 60.0 || rotzDegree <= -60.0)
		{
			butterflies[i].v *= -1.0;
			rotzDegree = CLAMP(-60.0, rotzDegree, 60.0);
		}
		GLfloat rotz = DegreeToRadian(rotzDegree);
		
		// scale along x
		GLint ind = (i%2 == 0) ? widthScaleIndex : 7-widthScaleIndex; //add some noise
		
		// compute the transformation matrix
        
        GLKMatrix4 Tz   = GLKMatrix4MakeTranslation(0.0, 0.0, -2.0);
        GLKMatrix4 S    = GLKMatrix4MakeScale(widthScale[ind]*0.2, 0.2, 1.0);
        GLKMatrix4 T    = GLKMatrix4MakeTranslation(butterflies[i].tx*s, butterflies[i].ty*s, butterflies[i].tz*sz);
        GLKMatrix4 Rz   = GLKMatrix4MakeZRotation(rotz);
        
        GLKMatrix4 M = GLKMatrix4Multiply(S, Tz);
        M = GLKMatrix4Multiply(T, M);
        M = GLKMatrix4Multiply(Rz, M);
		
		// simple quad data
		// 4D homogeneous coordinates (x,y,z,1)
		GLfloat pos[] = {
			-1,-1,0,1,	1,-1,0,1,	-1,1,0,1,	1, 1,0,1,
		};
		
		// first, position
		GLint v;
		for (v=0; v<4; v++) {
			// apply the resulting transformation matrix on each vertex
            GLKVector4 vout = GLKMatrix4MultiplyVector4(M, GLKVector4MakeWithArray(pos+v*4));
            
            GLfloat *temp = pos_tex_all+i*20+v*5;
            for (int t=0; t<4; t++)
                temp[t] = vout.v[t];
		}
		
		// then, tex coord
		for (j=0; j<8; j++)
		{
			GLint n = i*20 + (j/2)*5 + 3+j%2;
			GLint c = butterflies[i].c;
			pos_tex_all[n] = tex[c][j];
		}
		
		butterflies[i].t += butterflies[i].v;
	}
	
	// bind the texture atlas ONCE
	glBindTexture(GL_TEXTURE_2D, textureAtlas);
	
	glVertexPointer(3, GL_FLOAT, 5*sizeof(GLfloat), pos_tex_all);
	glTexCoordPointer(2, GL_FLOAT, 5*sizeof(GLfloat), pos_tex_all+3);
	
	// draw all butterflies using ONE single call
	glDrawElements(GL_TRIANGLE_STRIP, NUM_IMPOSTERS*6, GL_UNSIGNED_SHORT, indices_all);
	
	glBindTexture(GL_TEXTURE_2D, 0);
	
	// update parameters
	
	s += sanim;
	if ((s >= 1.5) || (s <= 1.0)) sanim *= -1.0;
	
	sz += szanim;
	if ((sz >= 1.4) || (sz <= -1.2)) szanim *= -1.0;
	
	GLfloat speed = CLAMP(0, kAnimationSpeed, 1);
	if (speed) {
		GLint speedInv = 1./speed;
		if (frameCount % speedInv == 0) {
			// update width scale to simulate the fly effect
			widthScaleIndex = widthScaleIndex < 7 ? widthScaleIndex+1 : 0;
		}
		frameCount ++;
	}
}

@end
