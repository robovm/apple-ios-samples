/*
     File: APLCrossDissolveRenderer.m
 Abstract: APLCrossDissolveRenderer subclass of APLOpenGLRenderer, renders the given source buffers to perform a cross dissolve over the time range of the transition.
  Version: 1.1
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "APLCrossDissolveRenderer.h"

@implementation APLCrossDissolveRenderer

- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer forTweenFactor:(float)tween
{
	[EAGLContext setCurrentContext:self.currentContext];
	
    if (foregroundPixelBuffer != NULL || backgroundPixelBuffer != NULL) {
        
        CVOpenGLESTextureRef foregroundLumaTexture  = [self lumaTextureForPixelBuffer:foregroundPixelBuffer];
        CVOpenGLESTextureRef foregroundChromaTexture = [self chromaTextureForPixelBuffer:foregroundPixelBuffer];
		
        CVOpenGLESTextureRef backgroundLumaTexture = [self lumaTextureForPixelBuffer:backgroundPixelBuffer];
        CVOpenGLESTextureRef backgroundChromaTexture = [self chromaTextureForPixelBuffer:backgroundPixelBuffer];
		
        CVOpenGLESTextureRef destLumaTexture = [self lumaTextureForPixelBuffer:destinationPixelBuffer];
        CVOpenGLESTextureRef destChromaTexture = [self chromaTextureForPixelBuffer:destinationPixelBuffer];
        
		glUseProgram(self.programY);
		
		// Set the render transform
		GLfloat preferredRenderTransform [] = {
			self.renderTransform.a, self.renderTransform.b, self.renderTransform.tx, 0.0,
			self.renderTransform.c, self.renderTransform.d, self.renderTransform.ty, 0.0,
			0.0,					   0.0,										1.0, 0.0,
			0.0,					   0.0,										0.0, 1.0,
		};
		
		glUniformMatrix4fv(uniforms[UNIFORM_RENDER_TRANSFORM_Y], 1, GL_FALSE, preferredRenderTransform);
		
        glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
        glViewport(0, 0, (int)CVPixelBufferGetWidthOfPlane(destinationPixelBuffer, 0), (int)CVPixelBufferGetHeightOfPlane(destinationPixelBuffer, 0));
		
		// Y planes of foreground and background frame are used to render the Y plane of the destination frame
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(foregroundLumaTexture), CVOpenGLESTextureGetName(foregroundLumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(CVOpenGLESTextureGetTarget(backgroundLumaTexture), CVOpenGLESTextureGetName(backgroundLumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		// Attach the destination texture as a color attachment to the off screen frame buffer
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destLumaTexture), CVOpenGLESTextureGetName(destLumaTexture), 0);
		
		if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
			NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
			goto bail;
		}
		
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);
        
        GLfloat quadVertexData1 [] = {
			-1.0, 1.0,
			1.0, 1.0,
			-1.0, -1.0,
			1.0, -1.0,
		};
		
		// texture data varies from 0 -> 1, whereas vertex data varies from -1 -> 1
		GLfloat quadTextureData1 [] = {
            0.5 + quadVertexData1[0]/2, 0.5 + quadVertexData1[1]/2,
            0.5 + quadVertexData1[2]/2, 0.5 + quadVertexData1[3]/2,
            0.5 + quadVertexData1[4]/2, 0.5 + quadVertexData1[5]/2,
            0.5 + quadVertexData1[6]/2, 0.5 + quadVertexData1[7]/2,
        };
        
		glUniform1i(uniforms[UNIFORM_Y], 0);
		
        glVertexAttribPointer(ATTRIB_VERTEX_Y, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(ATTRIB_VERTEX_Y);
        
        glVertexAttribPointer(ATTRIB_TEXCOORD_Y, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(ATTRIB_TEXCOORD_Y);
		
		// Blend function to draw the foreground frame
		glEnable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ZERO);
		
		// Draw the foreground frame
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
        glUniform1i(uniforms[UNIFORM_Y], 1);
        
        glVertexAttribPointer(ATTRIB_VERTEX_Y, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(ATTRIB_VERTEX_Y);
        
        glVertexAttribPointer(ATTRIB_TEXCOORD_Y, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(ATTRIB_TEXCOORD_Y);
		
		// Blend function to draw the background frame
        glBlendColor(0, 0, 0, tween);
        glBlendFunc(GL_CONSTANT_ALPHA, GL_ONE_MINUS_CONSTANT_ALPHA);
        
		// Draw the background frame
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		// Perform similar operations as above for the UV plane
		glUseProgram(self.programUV);
		
		glUniformMatrix4fv(uniforms[UNIFORM_RENDER_TRANSFORM_UV], 1, GL_FALSE, preferredRenderTransform);
		
		// UV planes of foreground and background frame are used to render the UV plane of the destination frame
		glActiveTexture(GL_TEXTURE2);
        glBindTexture(CVOpenGLESTextureGetTarget(foregroundChromaTexture), CVOpenGLESTextureGetName(foregroundChromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		glActiveTexture(GL_TEXTURE3);
		glBindTexture(CVOpenGLESTextureGetTarget(backgroundChromaTexture), CVOpenGLESTextureGetName(backgroundChromaTexture));
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		glViewport(0, 0, (int)CVPixelBufferGetWidthOfPlane(destinationPixelBuffer, 1), (int)CVPixelBufferGetHeightOfPlane(destinationPixelBuffer, 1));
		
		// Attach the destination texture as a color attachment to the off screen frame buffer
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destChromaTexture), CVOpenGLESTextureGetName(destChromaTexture), 0);
		
		if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
			NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
			goto bail;
		}
		
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);
        
		glUniform1i(uniforms[UNIFORM_UV], 2);
		
        glVertexAttribPointer(ATTRIB_VERTEX_UV, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(ATTRIB_VERTEX_UV);
        
        glVertexAttribPointer(ATTRIB_TEXCOORD_UV, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(ATTRIB_TEXCOORD_UV);
		
		glBlendFunc(GL_ONE, GL_ZERO);
		
		// Draw the foreground frame
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
        glUniform1i(uniforms[UNIFORM_UV], 3);
        
        glVertexAttribPointer(ATTRIB_VERTEX_UV, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(ATTRIB_VERTEX_UV);
        
        glVertexAttribPointer(ATTRIB_TEXCOORD_UV, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(ATTRIB_TEXCOORD_UV);
        
		glBlendColor(0, 0, 0, tween);
        glBlendFunc(GL_CONSTANT_ALPHA, GL_ONE_MINUS_CONSTANT_ALPHA);

		// Draw the background frame
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
        glFlush();
		
	bail:
		CFRelease(foregroundLumaTexture);
		CFRelease(foregroundChromaTexture);
		CFRelease(backgroundLumaTexture);
		CFRelease(backgroundChromaTexture);
		CFRelease(destLumaTexture);
		CFRelease(destChromaTexture);
		
		// Periodic texture cache flush every frame
		CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
		
		[EAGLContext setCurrentContext:nil];
    }
	
}

@end
