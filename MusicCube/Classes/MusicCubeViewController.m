/*
     File: MusicCubeViewController.m
 Abstract: n/a
  Version: 1.3
 
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


/*
 In our sound stage, the cube represents an omnidirectional sound source, and the teapot represents a sound listener.
 The four modes in the application shows how the sound volume and balance will change based on the position of the omnidirectional sound source
 and the position and rotation of the listener:
 1. Constant sound
 2. Sound variates corresponding to the listener's position changes relative to the source
 3. Sound variates corresponding to the listener's rotation changes relative to the source
 4. Sound variates corresponding to the listener's position and rotation changes relative to the source
 */

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES2/glext.h>

#import "MusicCubeViewController.h"
#import "teapot.h"


#define kInnerCircleRadius	1.0
#define kOuterCircleRadius	1.1
#define kCircleSegments     36

#define kTeapotScale		1.8
#define kCubeScale			0.12
#define kButtonScale		0.1

#define kButtonLeftSpace	1.1

#define	DegreesToRadians(x) ((x) * M_PI / 180.0)

#define BUFFER_OFFSET(i) ((char *)NULL + (i))


typedef struct
{
    GLKBaseEffect *effect;
    GLuint vertexArray;
    GLuint vertexBuffer;
    GLuint normalBuffer;
    
} BaseEffect;

// A class extension to declare private methods
@interface MusicCubeViewController ()
{
    BaseEffect innerCircle;
    BaseEffect outerCircle;
    BaseEffect teapot;
    BaseEffect cube[6];
    
    EAGLContext *context;
    
	GLuint mode;
	// teapot
	GLfloat rot;
	// cube
	GLfloat cubePos[3];
	GLfloat cubeRot;
    
    GLuint cubeTexture;
}
@end


@implementation MusicCubeViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
    if (!context || ![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
		
    mode = 1;
    
    glEnable(GL_DEPTH_TEST);
    
    // create base effects for our objects
    [self makeCircle:&innerCircle withNumOfSegments:kCircleSegments radius:kInnerCircleRadius];
    [self makeCircle:&outerCircle withNumOfSegments:kCircleSegments radius:kOuterCircleRadius];
    [self makeTeapot];
    [self makeCube];
    
    [self setupPlayback];
    
    [self createGestureRecognizers];
}

- (void)setupPlayback
{
    // initialize playback
	// the sound source (cube) starts at the center
	playback.sourcePos[0] = playback.sourcePos[1] = playback.sourcePos[2] = 0;
	// the linster (teapot) starts on the left side (in landscape)
	playback.listenerPos[0] = 0;
	playback.listenerPos[1] = (kInnerCircleRadius + kOuterCircleRadius) / 2.0;
	playback.listenerPos[2] = 0;
	// and points to the source (cube)
	playback.listenerRotation = 0;
    
    [playback startSound];
}

# pragma mark Create Objects
    
- (void)makeCircle:(BaseEffect *)circle withNumOfSegments:(GLint)segments radius:(GLfloat)radius
{
    GLfloat vertices[kCircleSegments*3];
    GLint count = 0;
	for (GLfloat i = 0; i < 360.0f; i += 360.0f/segments)
	{
		vertices[count++] = 0;									//x
		vertices[count++] = (cos(DegreesToRadians(i))*radius);	//y
		vertices[count++] = (sin(DegreesToRadians(i))*radius);	//z
	}
    
    GLKBaseEffect *effect = [[GLKBaseEffect alloc] init];
    effect.useConstantColor = YES;
    effect.constantColor = GLKVector4Make(0.2f, 0.7f, 0.2f, 1.0f);
    
    GLuint vertexArray, vertexBuffer;
    
    glGenVertexArraysOES(1, &vertexArray);
    glBindVertexArrayOES(vertexArray);
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    glBindVertexArrayOES(0);
    
    circle->effect = [effect retain];
    circle->vertexArray = vertexArray;
    circle->vertexBuffer = vertexBuffer;
    circle->normalBuffer = 0;
    
    [effect release];
}

- (void)makeTeapot
{
    GLKBaseEffect *effect = [[GLKBaseEffect alloc] init];
    // material
    effect.material.ambientColor = GLKVector4Make(0.4, 0.8, 0.4, 1.0);
    effect.material.diffuseColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    effect.material.specularColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    effect.material.shininess = 100.0;
    // light0
    effect.light0.enabled = GL_TRUE;
    effect.light0.ambientColor = GLKVector4Make(0.2, 0.2, 0.2, 1.0);
    effect.light0.diffuseColor = GLKVector4Make(0.2, 0.7, 0.2, 1.0);
    effect.light0.position = GLKVector4Make(0.0, 0.0, 1.0, 0.0);
    
    GLuint vertexArray, vertexBuffer, normalBuffer;
    
    glGenVertexArraysOES(1, &vertexArray);
    glBindVertexArrayOES(vertexArray);
    
    // position
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(teapot_vertices), teapot_vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    // normal
    glGenBuffers(1, &normalBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, normalBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(teapot_normals), teapot_normals, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    glBindVertexArrayOES(0);
    
    teapot.effect = [effect retain];
    teapot.vertexArray = vertexArray;
    teapot.vertexBuffer = vertexBuffer;
    teapot.normalBuffer = normalBuffer;
    
    [effect release];
}

-(void)makeCube
{
	// simple cube data
	// our sound source is omnidirectional, adjust the vertices
	// so that speakers in the textures point to all different directions
	const GLshort cubeVertices[6][20] = {
        //position3 texcoord2
		{ 1,-1, 1, 1, 0,   -1,-1, 1, 1, 1,   1, 1, 1, 0, 0,  -1, 1, 1, 0, 1 },
		{ 1, 1, 1, 1, 0,    1,-1, 1, 1, 1,   1, 1,-1, 0, 0,   1,-1,-1, 0, 1 },
		{-1, 1,-1, 1, 0,   -1,-1,-1, 1, 1,  -1, 1, 1, 0, 0,  -1,-1, 1, 0, 1 },
		{ 1, 1, 1, 1, 0,   -1, 1, 1, 1, 1,   1, 1,-1, 0, 0,  -1, 1,-1, 0, 1 },
		{ 1,-1,-1, 1, 0,   -1,-1,-1, 1, 1,   1, 1,-1, 0, 0,  -1, 1,-1, 0, 1 },
		{ 1,-1, 1, 1, 0,   -1,-1, 1, 1, 1,   1,-1,-1, 0, 0,  -1,-1,-1, 0, 1 },
	};
	
	const GLushort cubeColors[6][4] = {
		{1, 0, 0, 1}, {0, 1, 0, 1}, {0, 0, 1, 1}, {1, 1, 0, 1}, {0, 1, 1, 1}, {1, 0, 1, 1},
	};
    
    for (int f = 0; f < 6; f++)
    {
        GLKBaseEffect *effect = [[GLKBaseEffect alloc] init];
        // texture
        effect.texture2d0.enabled = GL_TRUE;
        // texture name is set later
        // tint color
        effect.useConstantColor = GL_TRUE;
        effect.constantColor = GLKVector4Make(cubeColors[f][0], cubeColors[f][1], cubeColors[f][2], cubeColors[f][3]);
    
        GLuint vertexArray, vertexBuffer;
    
        glGenVertexArraysOES(1, &vertexArray);
        glBindVertexArrayOES(vertexArray);
    
        glGenBuffers(1, &vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(cubeVertices[f]), cubeVertices[f], GL_STATIC_DRAW);
    
        // position
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_SHORT, GL_FALSE, 10, BUFFER_OFFSET(0));
        // texture cooridnates
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_SHORT, GL_FALSE, 10, BUFFER_OFFSET(6));
    
        glBindVertexArrayOES(0);
        
        cube[f].effect = [effect retain];
        cube[f].vertexArray = vertexArray;
        cube[f].vertexBuffer = vertexBuffer;
        cube[f].normalBuffer = 0;
        
        [effect release];
    }
    
    UIImage *image = [UIImage imageNamed:@"speaker.png"];
    GLKTextureLoader *textureloader = [[GLKTextureLoader alloc] initWithSharegroup:context.sharegroup];
    [textureloader textureWithCGImage:image.CGImage options:nil queue:nil completionHandler:^(GLKTextureInfo *textureInfo, NSError *error) {
        
        if(error) {
            NSLog(@"Error loading texture %@",error);
        }
        else {
            for (int f=0; f<6; f++)
                cube[f].effect.texture2d0.name = textureInfo.name;
            
            cubeTexture = textureInfo.name;
        }
    }];
}

# pragma mark Draw

- (void)drawTeapotAndUpdatePlayback
{
	int	start = 0, i = 0;
	
	rot -= 1.0f;
	GLfloat radius = (kOuterCircleRadius + kInnerCircleRadius) / 2.;
	GLfloat teapotPos[3] = {0.0f, cos(DegreesToRadians(rot))*radius, sin(DegreesToRadians(rot))*radius};
	
    // move clockwise along the circle
	GLKMatrix4 modelView = GLKMatrix4MakeTranslation(teapotPos[0], teapotPos[1], teapotPos[2]);
	modelView = GLKMatrix4Scale(modelView, kTeapotScale, kTeapotScale, kTeapotScale);
	
	// add rotation
	GLfloat rotYInRadians;
	if (mode == 2 || mode == 4)
		// in mode 2 and 4, the teapot (listener) always faces to one direction
		rotYInRadians = 0.0f;
	else
		// in mode 1 and 3, the teapot (listener) always faces to the cube (sound source)
		rotYInRadians = atan2(teapotPos[2]-cubePos[2], teapotPos[1]-cubePos[1]);
    
    modelView = GLKMatrix4Rotate(modelView, -M_PI_2, 0, 0, 1); //we want to display in landscape mode
    modelView = GLKMatrix4Rotate(modelView, rotYInRadians, 0, 1, 0);
    
    teapot.effect.transform.modelviewMatrix = modelView;
	
	// draw the teapot
    glBindVertexArrayOES(teapot.vertexArray);
    [teapot.effect prepareToDraw];
    
	while(i < num_teapot_indices) {
		if(teapot_indices[i] == -1) {
			glDrawElements(GL_TRIANGLE_STRIP, i - start, GL_UNSIGNED_SHORT, &teapot_indices[start]);
			start = i + 1;
		}
		i++;
	}
	if(start < num_teapot_indices)
		glDrawElements(GL_TRIANGLE_STRIP, i - start - 1, GL_UNSIGNED_SHORT, &teapot_indices[start]);
    
	
	// update playback
	playback.listenerPos = teapotPos; //listener's position
	playback.listenerRotation = rotYInRadians - M_PI; //listener's rotation in Radians
}

-(void)drawCube
{
	cubeRot += 3;
    
    GLKMatrix4 modelView = GLKMatrix4MakeTranslation(cubePos[0], cubePos[1], cubePos[2]);
    modelView = GLKMatrix4Scale(modelView, kCubeScale, kCubeScale, kCubeScale);
	
	if (mode <= 2)
		// origin of the teapot is at its bottom, but
		// origin of the cube is at its center, so move up a unit to put the cube on surface
		// we'll pass the bottom of the cube (cubePos) to the playback
        modelView = GLKMatrix4Translate(modelView, 1.0f, 0.0f, 0.0f);
	else
		// in mode 3 and 4, simply move up the cube a bit more to avoid colliding with the teapot
        modelView = GLKMatrix4Translate(modelView, 4.5f, 0.0f, 0.0f);
	
	// rotate around to simulate the omnidirectional effect
    modelView = GLKMatrix4Rotate(modelView, DegreesToRadians(cubeRot), 1, 0, 0);
    modelView = GLKMatrix4Rotate(modelView, DegreesToRadians(cubeRot), 0, 1, 1);
    
    for (int f=0; f<6; f++) {
        cube[f].effect.transform.modelviewMatrix = modelView;
        
        glBindVertexArrayOES(cube[f].vertexArray);
        [cube[f].effect prepareToDraw];
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClearDepthf(1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    GLfloat aspectRatio = (GLfloat)(view.drawableWidth) / (GLfloat)(view.drawableHeight);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(-1.0f, 1.0f, -1.0f/aspectRatio, 1.0f/aspectRatio, -10.0f, 10.0f);
    // rotate the camara for a better view
    projectionMatrix = GLKMatrix4Rotate(projectionMatrix, DegreesToRadians(-30.0f), 0.0f, 1.0f, 0.0f);
    
    // set the projection matrix
    innerCircle.effect.transform.projectionMatrix = projectionMatrix;
    outerCircle.effect.transform.projectionMatrix = projectionMatrix;
    teapot.effect.transform.projectionMatrix = projectionMatrix;
    for (int f=0; f<6; f++)
        cube[f].effect.transform.projectionMatrix = projectionMatrix;
    
    glBindVertexArrayOES(innerCircle.vertexArray);
    [innerCircle.effect prepareToDraw];
    glDrawArrays (GL_LINE_LOOP, 0, kCircleSegments);
    
    glBindVertexArrayOES(outerCircle.vertexArray);
    [outerCircle.effect prepareToDraw];
    glDrawArrays (GL_LINE_LOOP, 0, kCircleSegments);
    
    [self drawTeapotAndUpdatePlayback];
    
    [self drawCube];
}

- (void)deleteBaseEffect:(BaseEffect)e
{
    if (e.vertexBuffer)
        glDeleteBuffers(1, e.vertexBuffer);
    if (e.normalBuffer)
        glDeleteBuffers(1, e.normalBuffer);
    if (e.vertexArray)
        glDeleteVertexArraysOES(1, &e.vertexArray);
    [e.effect release];
}

- (void)dealloc {
    
	[playback stopSound];
    
    [self deleteBaseEffect:innerCircle];
    [self deleteBaseEffect:outerCircle];
    [self deleteBaseEffect:teapot];
    
	glDeleteTextures(1, &cubeTexture);
    
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];
	
    [super dealloc];
}

#pragma mark - Gesture Recognizers

- (void)createGestureRecognizers
{
    // Create a single tap recognizer and add it to the view
    UITapGestureRecognizer *recognizer;
    recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapFrom:)];
    recognizer.delegate = (id)self;
    [self.view addGestureRecognizer:recognizer];
    [recognizer release];
}

- (IBAction)handleSingleTapFrom:(UIGestureRecognizer *)sender
{
    mode++;
    if (mode > 4) mode = 1;
    
    // update the position of the cube (sound source)
    // in mode 1 and 2, the teapot (sound source) is at the center of the sound stage
    // in mode 3 and 4, the teapot (sound source) is on the left side
    if (mode <= 2) {
        cubePos[0] = cubePos[1] = cubePos[2] = 0;
    }
    else {
        cubePos[0] = 0;
        cubePos[1] = (kInnerCircleRadius + kOuterCircleRadius) / 2.0;
        cubePos[2] = 0;
    }
                
    // update playback
    playback.sourcePos = cubePos; //sound source's position
}

@end
