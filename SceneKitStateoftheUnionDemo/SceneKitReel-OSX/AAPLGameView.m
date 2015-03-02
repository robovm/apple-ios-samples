/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLGameView.h"

@implementation AAPLGameView {
    IBOutlet AAPLGameViewController *_gameViewController;
    NSPoint _clickLocation;
}

// forward click event to the game view controller
- (void)mouseDown:(NSEvent *)theEvent
{
    _clickLocation = [self convertPoint:theEvent.locationInWindow fromView:nil];
    
    [_gameViewController gestureDidBegin];
    
    if (theEvent.clickCount == 2) {
        [_gameViewController handleDoubleTapAtPoint:_clickLocation];
    }
    else {
        if (!(theEvent.modifierFlags & NSAlternateKeyMask)) {
            [_gameViewController handleTapAtPoint:_clickLocation];
        }
    }
    
    [super mouseDown:theEvent];
}

// forward drag event to the view controller as "pan" events
- (void)mouseDragged:(NSEvent *)theEvent
{
    if (theEvent.modifierFlags & NSAlternateKeyMask) {
        NSPoint p = [self convertPoint:theEvent.locationInWindow fromView:nil];
        [_gameViewController tiltCameraWithOffset:CGPointMake(p.x - _clickLocation.x, p.y - _clickLocation.y)];
    }
    else {
        [_gameViewController handlePanAtPoint:[self convertPoint:theEvent.locationInWindow fromView:nil]];
    }
    
    [super mouseDragged:theEvent];
}

// forward mouse up events as "end gesture"
- (void)mouseUp:(NSEvent *)theEvent
{
    [_gameViewController gestureDidEnd];
    [super mouseUp:theEvent];
}

@end
