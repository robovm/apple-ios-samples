/*
 File: APLCoffeeControl.m
 Abstract: Toggles the visibility coffee on the visible floor plan.
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

#import "APLCoffeeControl.h"
#import "APLCommon.h"

@interface APLCoffeeControl ()

- (IBAction)handleSwipe:(UISwipeGestureRecognizer *)swipeGestureRecognizer;

@end

@implementation APLCoffeeControl

#pragma mark - UIControl overrides

// Custom drawing method to draw the coffer control when it is enabled
//
- (void)drawRect:(CGRect)rect
{
    if ( self.enabled )
    {
        CGRect bounds = self.bounds;
        BOOL isOn = self.isOn;
        
        // Draw label
        NSAttributedString *labelAttributedString = [[NSAttributedString alloc] initWithString:@"Coffee" attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:kFontSize * 2.0], NSForegroundColorAttributeName : [UIColor blackColor] }];
        [labelAttributedString drawAtPoint:CGPointMake(CGRectGetMidX(bounds) - labelAttributedString.size.width * 0.5, kPadding * 2.0)];
        
        // Draw state
        NSAttributedString *offStateAttributedString = [[NSAttributedString alloc] initWithString:@"OFF" attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:kFontSize], NSForegroundColorAttributeName : ( !isOn ) ? [UIColor blackColor] : [UIColor lightGrayColor] }];
        NSAttributedString *onStateAttributedString = [[NSAttributedString alloc] initWithString:@"ON" attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:kFontSize], NSForegroundColorAttributeName : ( isOn ) ? [UIColor blackColor] : [UIColor lightGrayColor] }];
        if ( isOn )
        {
            [offStateAttributedString drawAtPoint:CGPointMake(CGRectGetMidX(bounds) + CGRectGetWidth(bounds) * 0.33 - offStateAttributedString.size.width * 0.5, CGRectGetMaxY(bounds) - kPadding * 2.0 - offStateAttributedString.size.height)];
            [onStateAttributedString drawAtPoint:CGPointMake(CGRectGetMidX(bounds) - onStateAttributedString.size.width * 0.5, CGRectGetMaxY(bounds) - kPadding * 2.0 - onStateAttributedString.size.height)];
        }
        else
        {
            [offStateAttributedString drawAtPoint:CGPointMake(CGRectGetMidX(bounds) - offStateAttributedString.size.width * 0.5, CGRectGetMaxY(bounds) - kPadding * 2.0 - offStateAttributedString.size.height)];
            [onStateAttributedString drawAtPoint:CGPointMake(CGRectGetMidX(bounds) - CGRectGetWidth(bounds) * 0.33 - onStateAttributedString.size.width * 0.5, CGRectGetMaxY(bounds) - kPadding * 2.0 - onStateAttributedString.size.height)];
        }
    }
}

// Override the enable property setter to redraw the control
//
- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self setNeedsDisplay];
}


#pragma mark - UIAccessibilityElement (UIAccessibilityTraitButton)

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityHint
{
    return @"Show or hide coffee locations";
}

- (NSString *)accessibilityLabel
{
    return @"Coffee";
}

- (NSString *)accessibilityValue
{
    return ( self.isOn ) ? @"On" : @"Off";
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

// Implement accessibilityActivate on an element in order to handle the default action.
// For example, if a native control requires a swipe gesture, you may implement this method so that a
// VoiceOver user will perform a double-tap to activate the item.
// If your implementation successfully handles activate, return YES, otherwise return NO.
// default == NO
//
- (BOOL)accessibilityActivate
{
    self.on = !self.isOn;
    return YES;
}

#pragma mark - Properties

- (void)setOn:(BOOL)on
{
    if ( on != _on )
    {
        _on = on;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
        [self setNeedsDisplay];
    }
}

#pragma mark - Actions

- (IBAction)handleSwipe:(UISwipeGestureRecognizer *)swipeGestureRecognizer
{
    UISwipeGestureRecognizerDirection direction = swipeGestureRecognizer.direction;
    BOOL isOn = self.isOn;
    
    if ( (direction == UISwipeGestureRecognizerDirectionLeft && isOn) || (direction == UISwipeGestureRecognizerDirectionRight && !isOn) )
    {
        self.on = !isOn;
    }
}

@end
