/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A visual representation of our sound stage.
*/

#import "oalSpatialView.h"

#import "oalPlayback.h"

CGPathRef CreateRoundedRectPath(CGRect RECT, CGFloat cornerRadius)
{
	CGMutablePathRef		path;
	path = CGPathCreateMutable();
	
	double		maxRad = MAX(CGRectGetHeight(RECT) / 2., CGRectGetWidth(RECT) / 2.);
	
	if (cornerRadius > maxRad) cornerRadius = maxRad;
	
	CGPoint		bl, tl, tr, br;
	
	bl = tl = tr = br = RECT.origin;
	tl.y += RECT.size.height;
	tr.y += RECT.size.height;
	tr.x += RECT.size.width;
	br.x += RECT.size.width;
	
	CGPathMoveToPoint(path, NULL, bl.x + cornerRadius, bl.y);
	CGPathAddArcToPoint(path, NULL, bl.x, bl.y, bl.x, bl.y + cornerRadius, cornerRadius);
	CGPathAddLineToPoint(path, NULL, tl.x, tl.y - cornerRadius);
	CGPathAddArcToPoint(path, NULL, tl.x, tl.y, tl.x + cornerRadius, tl.y, cornerRadius);
	CGPathAddLineToPoint(path, NULL, tr.x - cornerRadius, tr.y);
	CGPathAddArcToPoint(path, NULL, tr.x, tr.y, tr.x, tr.y - cornerRadius, cornerRadius);
	CGPathAddLineToPoint(path, NULL, br.x, br.y + cornerRadius);
	CGPathAddArcToPoint(path, NULL, br.x, br.y, br.x - cornerRadius, br.y, cornerRadius);
	
	CGPathCloseSubpath(path);
	
	CGPathRef				ret;
	ret = CGPathCreateCopy(path);
	CGPathRelease(path);
	return ret;
}

@implementation oalSpatialView

#pragma mark Object Init / Maintenance

- (id)initWithCoder:(NSCoder *)coder
{
	if (self = [super initWithCoder:coder]) {
		[self initializeContents];
	}
	return self;
}

- (void)dealloc
{
	[playback removeObserver:self forKeyPath:@"sourcePos"];
	[playback removeObserver:self forKeyPath:@"isPlaying"];
	[playback removeObserver:self forKeyPath:@"listenerPos"];
	[playback removeObserver:self forKeyPath:@"listenerRotation"];
	
	CGImageRelease(_speaker_off);
	CGImageRelease(_speaker_on);
	
	[super dealloc];
}

- (void)awakeFromNib
{	
	// We want to register as an observer for the oalPlayback environment, so we'll get notified when things 
	// change, i.e. source position, listener position.
	[playback addObserver:self forKeyPath:@"sourcePos" options:NSKeyValueObservingOptionNew context:NULL];
	[playback addObserver:self forKeyPath:@"isPlaying" options:NSKeyValueObservingOptionNew context:NULL];
	[playback addObserver:self forKeyPath:@"listenerPos" options:NSKeyValueObservingOptionNew context:NULL];
	[playback addObserver:self forKeyPath:@"listenerRotation" options:NSKeyValueObservingOptionNew context:NULL];

	[playback checkForMusic];
	[self layoutContents];
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// Generally, we just call [self layoutContents] whenever something changes in the oalPlayback environment. 
	// When the sound sound source is turned on or off, we also change the image for the speaker to either show 
	// or hide the sound waves.
	
	if ( (object == playback) && ([keyPath isEqualToString:@"sourcePos"]) ) {
		[self layoutContents];
	} 
	else if ( (object == playback) && [keyPath isEqualToString:@"isPlaying"] ) {
		[self layoutContents];
		if (playback.isPlaying)
			_speakerLayer.contents = (id)_speaker_on;
		else 
			_speakerLayer.contents = (id)_speaker_off;
	} 
	else if ( (object == playback) && ([keyPath isEqualToString:@"listenerPos"]) ) {
		[self layoutContents];
	} else if ( (object == playback) && ([keyPath isEqualToString:@"listenerRotation"]) ) {
		[self layoutContents];
	} else {
		[NSException raise:@"Error" format:@"%@ observing unexpected keypath %@ for object %@", self, keyPath, object];
	}
}



#pragma mark View contents

- (void)initializeContents
{
	// Load images for the two speaker states and retain them, because we'll be switching between them
	_speaker_off = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"speaker_off" ofType:@"png"]] CGImage];
	CGImageRetain(_speaker_off);
	_speaker_on = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"speaker_on" ofType:@"png"]] CGImage];

	CGImageRetain(_speaker_on);
	
	CGImageRef listenerImg = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"listener" ofType:@"png"]] CGImage];
	CGImageRef instructionsImg = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"instructions" ofType:@"png"]] CGImage];
	
	// Set up the CALayer which shows the speaker
	_speakerLayer = [CALayer layer];
	_speakerLayer.frame = CGRectMake(0., 0., CGImageGetWidth(_speaker_off), CGImageGetHeight(_speaker_off));
	_speakerLayer.contents = (id)_speaker_off;
	
	// Set up the CALayer which shows the listener
	_listenerLayer = [CALayer layer];
	_listenerLayer.frame = CGRectMake(0., 0., CGImageGetWidth(listenerImg), CGImageGetHeight(listenerImg));
	_listenerLayer.contents = (id)listenerImg;
	_listenerLayer.anchorPoint = CGPointMake(0.5, 0.57);
	
	// Set up the CALayer which shows the instructions
	_instructionsLayer = [CALayer layer];
	_instructionsLayer.frame = CGRectMake(0., 0., CGImageGetWidth(instructionsImg), CGImageGetHeight(instructionsImg));
	_instructionsLayer.position = CGPointMake(0., -140.);
	_instructionsLayer.contents = (id)instructionsImg;
	
	// Set a sublayerTransform on our view's layer. This causes (0,0) to be in the center of the view. This transform 
	// is useful because now our view's coordinates map precisely to our oalPlayback sound environment's coordinates.
	CATransform3D trans = CATransform3DMakeTranslation([self frame].size.width / 2., [self frame].size.height / 2., 0.);
	self.layer.sublayerTransform = trans;
	
	// Set the background image for the sound stage
	CGImageRef bgImg = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"stagebg" ofType:@"png"]] CGImage];
	self.layer.contents = (id)bgImg;

	// Add our sublayers
	[self.layer insertSublayer:_speakerLayer above:self.layer];
	[self.layer insertSublayer:_listenerLayer above:self.layer];
	[self.layer insertSublayer:_instructionsLayer above:self.layer];
	
	// Prevent things from drawing outside our layer bounds
	self.layer.masksToBounds = YES;	
}

- (void)layoutContents
{
	// layoutContents gets called via KVO whenever properties within our oalPlayback object change
	
	// Wrap these layer changes in a transaction and set the animation duration to 0 so we don't get implicit animation
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithDouble:0.] forKey:kCATransactionAnimationDuration];
	
	// Position and rotate the listener
	_listenerLayer.position = playback.listenerPos;
	_listenerLayer.transform = CATransform3DMakeRotation(playback.listenerRotation, 0., 0., 1.);
	
	// The speaker gets rotated so that it's always facing the listener
	CGFloat rot = atan2(-(playback.sourcePos.x - playback.listenerPos.x), playback.sourcePos.y - playback.listenerPos.y);
	
	// Rotate and position the speaker
	_speakerLayer.position = playback.sourcePos;
	_speakerLayer.transform = CATransform3DMakeRotation(rot, 0., 0., 1.);
	
	[CATransaction commit];
}


#pragma mark Events

- (void)touchPoint:(CGPoint)pt
{
	if (!(_instructionsLayer.hidden)) _instructionsLayer.hidden = YES;
	
	if (_draggingLayer == _speakerLayer) playback.sourcePos = pt;
	else if (_draggingLayer == _listenerLayer) playback.listenerPos = pt;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	CGPoint pointInView = [[touches anyObject] locationInView:self];
		
	// Clip our pointInView to within 5 pixels of any edge, so we can't position objects near or beyond 
	// the edge of the sound stage
	pointInView = CGPointWithinBounds(pointInView, CGRectInset([self bounds], 5., 5.));
	
	// Convert the view point to our layer / sound stage coordinate system, which is centered at (0,0)
	CGPoint pointInLayer = CGPointMake(pointInView.x - [self frame].size.width / 2., pointInView.y - [self frame].size.height / 2.);
	
	// Find out if the distance between the touch is within the tolerance threshhold for moving
	// the source object or the listener object
	if (hypot(playback.sourcePos.x - pointInLayer.x, playback.sourcePos.y - pointInLayer.y) < kTouchDistanceThreshhold)
	{
		_draggingLayer = _speakerLayer;
	}
	else if (hypot(playback.listenerPos.x - pointInLayer.x, playback.listenerPos.y - pointInLayer.y) < kTouchDistanceThreshhold)
	{
		_draggingLayer = _listenerLayer;
	}
	else
	{
		_draggingLayer = nil;
	}
	
	// Handle the touch
	[self touchPoint:pointInLayer];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	// Called repeatedly as the touch moves
	
	CGPoint pointInView = [[touches anyObject] locationInView:self];
	pointInView = CGPointWithinBounds(pointInView, CGRectInset([self bounds], 5., 5.));
	CGPoint pointInLayer = CGPointMake(pointInView.x - [self frame].size.width / 2., pointInView.y - [self frame].size.height / 2.);
	[self touchPoint:pointInLayer];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	_draggingLayer = nil;
}



@end
