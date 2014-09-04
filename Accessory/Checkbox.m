/*
     File: Checkbox.m
 Abstract: A UIControl subclass that implements a checkbox.
 
  Version: 1.4
 
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

#import <QuartzCore/QuartzCore.h>

#import "Checkbox.h"

@implementation Checkbox
{
    // This variable is only used on iOS 6.  On iOS 7, calls to read/write the
    // tintColor property are forwarded to the super (UIView).
    //
    // We must manually define it because we've manually implemented both the
    // getter and setter for the 'tintColor' property.
    UIColor *_tintColor;
}

//| ----------------------------------------------------------------------------
- (void)tintColorDidChange
{
    [self setNeedsDisplay];
}


//| ----------------------------------------------------------------------------
//! Manual implementation of the getter for the 'tintColor' property.
//
//  The getter for this property is implemented to forward invcations to the
//  super if the device is running iOS 7.
//
- (UIColor*)tintColor
{
    // On iOS 7, forward to the super (UIView).
    if ([[super superclass] instancesRespondToSelector:@selector(tintColor)])
        return [super tintColor];
    else
        return _tintColor;
}


//| ----------------------------------------------------------------------------
//! Manual implementation of the setter for the 'tintColor' property.
//
//  The setter for this property is implemented to forward invcations to the
//  super if the device is running iOS 7.
//
- (void)setTintColor:(UIColor *)tintColor
{
    // On iOS 7, forward to the super (UIView).
    if ([[super superclass] instancesRespondToSelector:@selector(setTintColor:)])
        return [super setTintColor:tintColor];
    else
        _tintColor = tintColor;
}


//| ----------------------------------------------------------------------------
//  This method is overridden to draw the control using Quartz2D.
//
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    const CGFloat size = MIN(self.bounds.size.width, self.bounds.size.height);
    CGAffineTransform transform = CGAffineTransformIdentity;

    // Account for non-square frames.
    if (self.bounds.size.width < self.bounds.size.height) {
        // Vertical Center
        transform = CGAffineTransformMakeTranslation(0, (self.bounds.size.height - size)/2);
    } else if (self.bounds.size.width > self.bounds.size.height) {
        // Horizontal Center
        transform = CGAffineTransformMakeTranslation((self.bounds.size.width - size)/2, 0);
    }
    
    // Draw the checkbox
    {
        const CGFloat strokeWidth = 0.068359375f * size;
        const CGFloat checkBoxInset = 0.171875f * size;
        
        CGRect checkboxRect = CGRectMake(checkBoxInset, checkBoxInset, size - checkBoxInset*2, size - checkBoxInset*2);
        UIBezierPath *checkboxPath = [UIBezierPath bezierPathWithRect:checkboxRect];
        
        [checkboxPath applyTransform:transform];
        
        if (!self.tintColor)
            self.tintColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
        [self.tintColor setStroke];
        
        checkboxPath.lineWidth = strokeWidth;
        
        [checkboxPath stroke];
    }
    
    // Draw the checkmark if self.checked==YES
    if (self.checked)
    {
        // The checkmark is drawn as a bezier path using Quartz2D.
        // The control points for this path are stored (hardcoded) as normalized
        // values so that the path can be accurately reconstructed at any size.
        
        // A small macro to scale the normalized control points for the
        // checkmark bezier path to the size of the control.
    #define P(POINT) (POINT * size)
        
        CGContextSetGrayFillColor(context, 0.0f, 1.0f);
        CGContextConcatCTM(context, transform);
        
        CGContextBeginPath(context);
        CGContextMoveToPoint(context,
                             P(0.304f), P(0.425f));
        CGContextAddLineToPoint(context, P(0.396f), P(0.361f));
        CGContextAddCurveToPoint(context,
                                 P(0.396f), P(0.361f),
                                 P(0.453f), P(0.392f),
                                 P(0.5f), P(0.511f));
        CGContextAddCurveToPoint(context,
                                 P(0.703f), P(0.181f),
                                 P(0.988f), P(0.015f),
                                 P(0.988f), P(0.015f));
        CGContextAddLineToPoint(context, P(0.998f), P(0.044f));
        CGContextAddCurveToPoint(context,
                                 P(0.998f), P(0.044f),
                                 P(0.769f), P(0.212f),
                                 P(0.558f), P(0.605f));
        CGContextAddLineToPoint(context, P(0.458f), P(0.681f));
        CGContextAddCurveToPoint(context,
                                 P(0.365f), P(0.451f),
                                 P(0.304f), P(0.425f),
                                 P(0.302f), P(0.425f));
        CGContextClosePath(context);
        
        CGContextFillPath(context);
        
    #undef P
    }
    

}

#pragma mark - 
#pragma mark Control

//| ----------------------------------------------------------------------------
//! Custom implementation of the setter for the 'checked' property.
//
- (void)setChecked:(BOOL)checked
{
    if (checked != _checked) {
        _checked = checked;
        
        // Flag ourself as needing to be redrawn.
        [self setNeedsDisplay];
        
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }
}


//| ----------------------------------------------------------------------------
//! Sends action messages for the given control events along with the UIEvent
//! which triggered them.
//
//  UIControl provides the -sendActionsForControlEvents: method to send action
//  messages associated with controlEvents.  A limitation of
//  -sendActionsForControlEvents is that it does not include the UIEvent that
//  triggered the controlEvents with the action messages.
//
//  AccessoryViewController and CustomAccessoryViewController rely on receiving
//  the underlying UIEvent when their associated IBActions are invoked.
//  This method functions identically to -sendActionsForControlEvents:
//  but accepts a UIEvent that is sent with the action messages.
//
- (void)sendActionsForControlEvents:(UIControlEvents)controlEvents withEvent:(UIEvent*)event
{
    NSSet *allTargets = [self allTargets];
    
    for (id target in allTargets) {
        
        NSArray *actionsForTarget = [self actionsForTarget:target forControlEvent:controlEvents];
        
        // Actions are returned as NSString objects, where each string is the
        // selector for the action.
        for (NSString *action in actionsForTarget) {
            SEL selector = NSSelectorFromString(action);
            [self sendAction:selector to:target forEvent:event];
        }
    }
}


//| ----------------------------------------------------------------------------
//  If you override one of the touch event callbacks, you should override all of
//  them.
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{ }


//| ----------------------------------------------------------------------------
//  If you override one of the touch event callbacks, you should override all of
//  them.
//
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{ }

//| ----------------------------------------------------------------------------
//  This is the touch callback we are interested in.  If there is a touch inside
//  our bounds, toggle our checked state and notify our target of the change.
//
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[touches anyObject] tapCount] == 1) {
        // Toggle our state.
        self.checked = !self.checked;
        
        // Notify our target (if we have one) of the change.
        [self sendActionsForControlEvents:UIControlEventValueChanged withEvent:event];
    }
}


//| ----------------------------------------------------------------------------
//  If you override one of the touch event callbacks, you should override all of
//  them.
//
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{ }

#pragma mark -
// If you implement a custom control, you should put in the extra work to
// make it accessible.  Your users will appreciate it.
#pragma mark Accessibility

//| ----------------------------------------------------------------------------
//  Declare that this control is accessible element to assistive applications.
//
- (BOOL)isAccessibilityElement
{
    return YES;
}

// Note: accessibilityHint and accessibilityLabel should be configured
//       elsewhere because this control does not know its purpose
//       as it relates to the program as a whole.


//| ----------------------------------------------------------------------------
- (UIAccessibilityTraits)accessibilityTraits
{
    // Always combine our accessibilityTraits with the super's
    // accessibilityTraits
    return super.accessibilityTraits | UIAccessibilityTraitButton;
}


//| ----------------------------------------------------------------------------
- (NSString*)accessibilityValue
{
    return self.checked ? @"Enabled" : @"Disabled";
}

@end
