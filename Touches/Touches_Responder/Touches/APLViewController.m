/*
     File: APLViewController.m
 Abstract: The main view controller for this application.
  Version: 2.0
 
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

#import "APLViewController.h"

@interface APLViewController ()

@end


@interface APLViewController ()
{
	BOOL piecesOnTop;  // Keeps track of whether two or more pieces are on top of each other.
	CGPoint startTouchPosition;
}

// Views the user can move
@property (nonatomic, strong) IBOutlet UIImageView *firstPieceView;
@property (nonatomic, strong) IBOutlet UIImageView *secondPieceView;
@property (nonatomic, strong) IBOutlet UIImageView *thirdPieceView;

@property (nonatomic, strong) IBOutlet UILabel *touchPhaseText; // Displays the touch phase.
@property (nonatomic, strong) IBOutlet UILabel *touchInfoText; // Displays touch information for  multiple taps.
@property (nonatomic, strong) IBOutlet UILabel *touchTrackingText; // Displays touch tracking information
@property (nonatomic, strong) IBOutlet UILabel *touchInstructionsText; // Displays instructions for how to split apart pieces that are on top of each other.
@end


@implementation APLViewController

#define GROW_ANIMATION_DURATION_SECONDS 0.15    // Determines how fast a piece size grows when it is moved.
#define SHRINK_ANIMATION_DURATION_SECONDS 0.15  // Determines how fast a piece size shrinks when a piece stops moving.

#pragma mark - Touch handling

/**
 Handles the start of a touch.
 */
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSUInteger numTaps = [[touches anyObject] tapCount];

    
	self.touchPhaseText.text = NSLocalizedString(@"Phase: Touches began", @"Phase label text for touches began");
	self.touchInfoText.text = @"";
	if (numTaps >= 2) {
        NSString *infoFormatString = NSLocalizedString(@"%d taps", @"Format string for info text for number of taps");
		self.touchInfoText.text = [NSString stringWithFormat:infoFormatString, numTaps];
		if ((numTaps == 2) && piecesOnTop) {
			// A double tap positions the three pieces in a diagonal.
			// The user will want to double tap when two or more pieces are on top of each other
			if (self.firstPieceView.center.x == self.secondPieceView.center.x)
				self.secondPieceView.center = CGPointMake(self.firstPieceView.center.x - 50, self.firstPieceView.center.y - 50);
			if (self.firstPieceView.center.x == self.thirdPieceView.center.x)
				self.thirdPieceView.center  = CGPointMake(self.firstPieceView.center.x + 50, self.firstPieceView.center.y + 50);
			if (self.secondPieceView.center.x == self.thirdPieceView.center.x)
				self.thirdPieceView.center  = CGPointMake(self.secondPieceView.center.x + 50, self.secondPieceView.center.y + 50);
			self.touchInstructionsText.text = @"";
		}
	}
    else {
		self.touchTrackingText.text = @"";
	}
	// Enumerate through all the touch objects.
	NSUInteger touchCount = 0;
	for (UITouch *touch in touches) {
		// Send to the dispatch method, which will make sure the appropriate subview is acted upon.
		[self dispatchFirstTouchAtPoint:[touch locationInView:self.view] forEvent:nil];
		touchCount++;
	}
}

/**
 Checks to see which view, or views, the point is in and then calls a method to perform the opening animation, which  makes the piece slightly larger, as if it is being picked up by the user.
 */
-(void)dispatchFirstTouchAtPoint:(CGPoint)touchPoint forEvent:(UIEvent *)event
{
	if (CGRectContainsPoint(self.firstPieceView.frame, touchPoint)) {
		[self animateFirstTouchAtPoint:touchPoint forView:self.firstPieceView];
	}
	if (CGRectContainsPoint(self.secondPieceView.frame, touchPoint)) {
		[self animateFirstTouchAtPoint:touchPoint forView:self.secondPieceView];
	}
	if (CGRectContainsPoint(self.thirdPieceView.frame, touchPoint)) {
		[self animateFirstTouchAtPoint:touchPoint forView:self.thirdPieceView];
	}

}

/**
 Handles the continuation of a touch.
 */
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSUInteger touchCount = 0;
    self.touchPhaseText.text = NSLocalizedString(@"Phase: Touches moved", @"Phase label text for touches moved");
	// Enumerates through all touch objects
	for (UITouch *touch in touches) {
		// Send to the dispatch method, which will make sure the appropriate subview is acted upon
		[self dispatchTouchEvent:[touch view] toPosition:[touch locationInView:self.view]];
		touchCount++;
	}

	// When multiple touches, report the number of touches.
	if (touchCount > 1) {
        NSString *trackingFormatString = NSLocalizedString(@"Tracking %d touches", @"Format string for tracking text for number of touches being tracked");
		self.touchTrackingText.text = [NSString stringWithFormat:trackingFormatString, touchCount];
	}
    else {
		self.touchTrackingText.text = NSLocalizedString(@"Tracking 1 touch", @"String for tracking text for 1 touch being tracked");
	}
}


/**
 Checks to see which view, or views, the point is in and then sets the center of each moved view to the new postion.
 If views are directly on top of each other, they move together.
 */
-(void)dispatchTouchEvent:(UIView *)theView toPosition:(CGPoint)position
{
	// Check to see which view, or views,  the point is in and then move to that position.
	if (CGRectContainsPoint([self.firstPieceView frame], position)) {
		self.firstPieceView.center = position;
	}
	if (CGRectContainsPoint([self.secondPieceView frame], position)) {
		self.secondPieceView.center = position;
	}
	if (CGRectContainsPoint([self.thirdPieceView frame], position)) {
		self.thirdPieceView.center = position;
	}
}

/**
 Handles the end of a touch event.
 */
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touchPhaseText.text = NSLocalizedString(@"Phase: Touches ended", @"Phase label text for touches ended");
	// Enumerates through all touch object
	for (UITouch *touch in touches) {
		// Sends to the dispatch method, which will make sure the appropriate subview is acted upon
		[self dispatchTouchEndEvent:[touch view] toPosition:[touch locationInView:self.view]];
	}
}


/**
 Checks to see which view, or views,  the point is in and then calls a method to perform the closing animation, which is to return the piece to its original size, as if it is being put down by the user.
 */
-(void)dispatchTouchEndEvent:(UIView *)theView toPosition:(CGPoint)position
{
	// Check to see which view, or views, the point is in and then animate to that position.
	if (CGRectContainsPoint([self.firstPieceView frame], position)) {
		[self animateView:self.firstPieceView toPosition: position];
	}
	if (CGRectContainsPoint([self.secondPieceView frame], position)) {
		[self animateView:self.secondPieceView toPosition: position];
	}
	if (CGRectContainsPoint([self.thirdPieceView frame], position)) {
		[self animateView:self.thirdPieceView toPosition: position];
	}
    
	// If one piece obscures another, display a message so the user can move the pieces apart.
	if (CGPointEqualToPoint(self.firstPieceView.center, self.secondPieceView.center) ||
		CGPointEqualToPoint(self.firstPieceView.center, self.thirdPieceView.center) ||
		CGPointEqualToPoint(self.secondPieceView.center, self.thirdPieceView.center)) {
        
		self.touchInstructionsText.text = NSLocalizedString(@"Double tap the background to move the pieces apart.", @"Instructions text string.");
		piecesOnTop = YES;
	} else {
		piecesOnTop = NO;
	}
}


-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touchPhaseText.text = NSLocalizedString(@"Phase: Touches cancelled", @"Phase label text for touches cancelled");
	// Enumerates through all touch objects.
	for (UITouch *touch in touches) {
		// Sends to the dispatch method, which will make sure the appropriate subview is acted upon.
		[self dispatchTouchEndEvent:[touch view] toPosition:[touch locationInView:self.view]];
	}
}

#pragma mark - Animating subviews

/**
 Scales up a view slightly which makes the piece slightly larger, as if it is being picked up by the user.
 */
-(void)animateFirstTouchAtPoint:(CGPoint)touchPoint forView:(UIImageView *)theView
{
	// Pulse the view by scaling up, then move the view to under the finger.
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:GROW_ANIMATION_DURATION_SECONDS];
	theView.transform = CGAffineTransformMakeScale(1.2, 1.2);
	[UIView commitAnimations];
}


/**
 Scales down the view and moves it to the new position.
  */
-(void)animateView:(UIView *)theView toPosition:(CGPoint)thePosition
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:SHRINK_ANIMATION_DURATION_SECONDS];
	// Set the center to the final postion.
	theView.center = thePosition;
	// Set the transform back to the identity, thus undoing the previous scaling effect.
	theView.transform = CGAffineTransformIdentity;
	[UIView commitAnimations];
}


@end