/*
 File: APLElevatorControl.m
 Abstract: A custom UIControl to control the floor of plan view.
 Version: 1.0
 
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

#import "APLElevatorControl.h"
#import "APLCommon.h"

typedef enum : NSUInteger {
    ControlDirectionDown = 1,
    ControlDirectionUp
} TControlDirection;

@interface APLElevatorControl ()

@property (nonatomic) CGPoint touchPoint;

@end

@implementation APLElevatorControl

#pragma mark - UIControl overrides

// Custom drawing method to draw the elevator control when it is enabled
//
- (void)drawRect:(CGRect)rect
{
    if ( self.enabled )
    {
        BOOL downControlEnabled = [self controlEnabledForDirection:ControlDirectionDown];
        CGRect downControlRect = [self controlRectForDirection:ControlDirectionDown];
        BOOL upControlEnabled = [self controlEnabledForDirection:ControlDirectionUp];
        CGRect upControlRect = [self controlRectForDirection:ControlDirectionUp];
        
        // Draw down control
        NSAttributedString *downControlAttributedString = [[NSAttributedString alloc] initWithString:@"Down" attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:kFontSize], NSForegroundColorAttributeName : ( !downControlEnabled ) ? [UIColor lightGrayColor] : [UIColor blackColor] }];
        UIBezierPath *downControlBezierPath = [UIBezierPath bezierPathWithOvalInRect:downControlRect];
        downControlBezierPath.lineWidth = kLineWidth;
        [( downControlEnabled && [self controlTouchedForDirection:ControlDirectionDown] ) ? [UIColor darkGrayColor] : [UIColor whiteColor] setFill];
        [downControlBezierPath fill];
        [( downControlEnabled ) ? [UIColor blackColor] : [UIColor lightGrayColor] setStroke];
        [downControlBezierPath stroke];
        [downControlAttributedString drawAtPoint:CGPointMake(CGRectGetMidX(downControlRect) - downControlAttributedString.size.width * 0.5, CGRectGetMidY(downControlRect) - downControlAttributedString.size.height * 0.5)];
        
        // Draw up control
        NSAttributedString *upControlAttributedString = [[NSAttributedString alloc] initWithString:@"Up" attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:kFontSize], NSForegroundColorAttributeName : ( !upControlEnabled ) ? [UIColor lightGrayColor] : [UIColor blackColor] }];
        UIBezierPath *upControlBezierPath = [UIBezierPath bezierPathWithOvalInRect:upControlRect];
        upControlBezierPath.lineWidth = kLineWidth;
        [( upControlEnabled && [self controlTouchedForDirection:ControlDirectionUp] ) ? [UIColor darkGrayColor] : [UIColor whiteColor] setFill];
        [upControlBezierPath fill];
        [( upControlEnabled ) ? [UIColor blackColor] : [UIColor lightGrayColor] setStroke];
        [upControlBezierPath stroke];
        [upControlAttributedString drawAtPoint:CGPointMake(CGRectGetMidX(upControlRect) - upControlAttributedString.size.width * 0.5, CGRectGetMidY(upControlRect) - upControlAttributedString.size.height * 0.5)];
    }
}

// Return YES when the elevator control is touched.
//
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    self.touchPoint = [touch locationInView:self];
    if ( [self controlTouchedForDirection:ControlDirectionDown] || [self controlTouchedForDirection:ControlDirectionUp] )
    {
        [self setNeedsDisplay];
        return YES;
    }
    return NO;
}

// Increase or decrease the floor when touched end
//
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Decrement floor
    if ( [self controlTouchedForDirection:ControlDirectionDown] )
    {
        [self decrementFloor];
    }
    // Increment floor
    else if ( [self controlTouchedForDirection:ControlDirectionUp] )
    {
        [self incrementFloor];
    }
    self.touchPoint = CGPointZero;
}

// Override the enable property setter to redraw the control
//
- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self setNeedsDisplay];
}



#pragma mark - UIAccessibilityElement (UIAccessibilityTraitAdjustable)

// Basic UIAccessibilityElement method
//
- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityValue
{
    // Return a formatted number string
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    return [numberFormatter stringFromNumber:[NSNumber numberWithInteger:self.floor]];
}

- (NSString *)accessibilityLabel
{
    return @"Floor";
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitAdjustable;
}

// If an element has the UIAccessibilityTraitAdjustable trait, it must also implement
// the following methods. Incrementing will adjust the element so that it increases its content,
// while decrementing decreases its content. For example, accessibilityIncrement will increase the value
// of a UISlider, and accessibilityDecrement will decrease the value.
//
- (void)accessibilityDecrement
{
    [self decrementFloor];
    
    // Increase the floor will trigger UI layout changes, so post the notificaiton
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (void)accessibilityIncrement
{
    [self incrementFloor];
    
    // Decrease the floor will trigger UI layout changes, so post the notificaiton
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

#pragma mark - Helpers

// Return the enable / disable status based on current floor
//
- (BOOL)controlEnabledForDirection:(TControlDirection)controlDirection
{
    switch ( controlDirection )
    {
        case ControlDirectionDown:
            return self.floor > kMinimumFloor;
        case ControlDirectionUp:
            return self.floor < kMaximumFloor;
        default:
            // Unsupported control direction
            return NO;
    }
}

- (CGRect)controlRectForDirection:(TControlDirection)controlDirection
{
    CGRect bounds = self.bounds;
    CGFloat controlWidth = CGRectGetWidth(bounds) - kPadding * 2.0;
    
    switch ( controlDirection )
    {
        case ControlDirectionDown:
            return CGRectMake(kPadding, CGRectGetHeight(bounds) - kPadding - controlWidth, controlWidth, controlWidth);
        case ControlDirectionUp:
            return CGRectMake(kPadding, kPadding, controlWidth, controlWidth);
        default:
            // Unsupported control direction
            return CGRectZero;
    }
}

// Return YES if the touched point is within the control rect.
//
- (BOOL)controlTouchedForDirection:(TControlDirection)controlDirection
{
    return CGRectContainsPoint([self controlRectForDirection:controlDirection], self.touchPoint);
}

// Decrease the floor and trigger the event handler
//
- (void)decrementFloor
{
    if ( [self controlEnabledForDirection:ControlDirectionDown] )
    {
        self.floor -= 1;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

// Increase the floor and trigger the event handler
//
- (void)incrementFloor
{
    if ( [self controlEnabledForDirection:ControlDirectionUp] )
    {
        self.floor += 1;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}


#pragma mark - Properties

- (void)setFloor:(NSInteger)floor
{
    // Clamp floor between [kMinimumFloor, kMaximumFloor]
    _floor = MAX(MIN(floor, kMaximumFloor), kMinimumFloor);
    [self setNeedsDisplay];
}

@end
