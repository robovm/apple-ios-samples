/*

<codex>

*/

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "LevelMeter.h"

@interface GLLevelMeter : LevelMeter {
	GLint           _backingWidth;
	GLint           _backingHeight;
	EAGLContext     *_context;
	GLuint          _viewRenderbuffer, _viewFramebuffer;
}

@end
