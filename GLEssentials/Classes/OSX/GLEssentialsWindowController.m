/*
     File: GLEssentialsWindowController.m
 Abstract: 
 Window controller class. Necessary to switch back and forth between a fullscreen and non-fullscreen window.
 The window property on NSWindowController is connected to the window in the NIB (via Interface Builder).
 
  Version: 1.7
 
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

#import "GLEssentialsWindowController.h"
#import "GLEssentialsFullscreenWindow.h"

@interface GLEssentialsWindowController ()

@end

@implementation GLEssentialsWindowController

// Were we set in the background?
BOOL wasBackgroundedOutOfFullScreen;


// Fullscreen window 
GLEssentialsFullscreenWindow *fullscreenWindow;

// Non-Fullscreen window (also the initial window)
NSWindow* standardWindow;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];

	if (self)
	{
		// Initialize to nil since it indicates app is not fullscreen
		fullscreenWindow = nil;
    }

	return self;
}

- (void) goFullscreen
{
	// If app is already fullscreen...
	if(fullscreenWindow)
	{
		//...don't do anything
		return;
	}

	// Allocate a new fullscreen window
	fullscreenWindow = [[GLEssentialsFullscreenWindow alloc] init];

	// Resize the view to screensize
	NSRect viewRect = [fullscreenWindow frame];

	// Set the view to the size of the fullscreen window
	[view setFrameSize: viewRect.size];

	// Set the view in the fullscreen window
	[fullscreenWindow setContentView:view];

	standardWindow = [self window];

	// Hide non-fullscreen window so it doesn't show up when switching out
	// of this app (i.e. with CMD-TAB)
	[standardWindow orderOut:self];

	// Set controller to the fullscreen window so that all input will go to
	// this controller (self)
	[self setWindow:fullscreenWindow];

	// Show the window and make it the key window for input
	[fullscreenWindow makeKeyAndOrderFront:self];

}

- (void) goWindow
{
	// If controller doesn't have a full screen window...
	if(fullscreenWindow == nil)
	{
		//...app is already windowed so don't do anything
		return;
	}

	// Get the rectangle of the original window
	NSRect viewRect = [standardWindow frame];
	
	// Set the view rect to the new size
	[view setFrame:viewRect];

	// Set controller to the standard window so that all input will go to
	// this controller (self)
	[self setWindow:standardWindow];

	// Set the content of the orginal window to the view
	[[self window] setContentView:view];

	// Show the window and make it the key window for input
	[[self window] makeKeyAndOrderFront:self];

	// Release the fullscreen window
	[fullscreenWindow release];

	// Ensure we set fullscreen Window to nil so our checks for 
	// windowed vs. fullscreen mode elsewhere are correct
	fullscreenWindow = nil;
}


- (void) keyDown:(NSEvent *)event
{
	unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];

	switch (c)
	{
		// Handle [ESC] key
		case 27:
			if(fullscreenWindow != nil)
			{
				[self goWindow];
			}
			return;
		// Have f key toggle fullscreen
		case 'f':
			if(fullscreenWindow == nil)
			{
				[self goFullscreen];
			}
			else
			{
				[self goWindow];
			}
			return;
	}

	// Allow other character to be handled (or not and beep)
	[super keyDown:event];
}

@end
