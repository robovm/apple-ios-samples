/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A visual representation of our sound stage.
*/

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

#define kTouchDistanceThreshhold 45.

// A function to bring an outlying point into the bounds of a rectangle,
// so that it is as close as possible to its original outlying position.
static inline CGPoint CGPointWithinBounds(CGPoint point, CGRect bounds)
{
	CGPoint ret = point;
	if (ret.x < CGRectGetMinX(bounds)) ret.x = CGRectGetMinX(bounds);
	else if (ret.x > CGRectGetMaxX(bounds)) ret.x = CGRectGetMaxX(bounds);
	if (ret.y < CGRectGetMinY(bounds)) ret.y = CGRectGetMinY(bounds);
	else if (ret.y > CGRectGetMaxY(bounds)) ret.y = CGRectGetMaxY(bounds);
	return ret;
}

@class oalPlayback;

@interface oalSpatialView : UIView
{
	// Reference to our playback object, wired up in IB
	IBOutlet oalPlayback		*playback;
	
	// Images for the speaker in its on and off state
	CGImageRef					_speaker_off;
	CGImageRef					_speaker_on;
	
	// Various layers we use to represent things in the sound stage
	CALayer						*_draggingLayer;
	CALayer						*_speakerLayer;
	CALayer						*_listenerLayer;
	CALayer						*_instructionsLayer;
}

- (void)initializeContents;

- (void)layoutContents;

@end
