/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A UIControl subclass that implements a checkbox.
 */

#import "Checkbox.h"

@implementation Checkbox

//  This method is overridden to draw the control using Quartz2D.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    const CGFloat size = MIN(self.bounds.size.width, self.bounds.size.height);
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    // Account for non-square frames.
    if (self.bounds.size.width < self.bounds.size.height)
    {
        // Vertical Center
        transform = CGAffineTransformMakeTranslation(0, (self.bounds.size.height - size)/2);
    } else if (self.bounds.size.width > self.bounds.size.height)
    {
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
        
        self.tintColor = [UIColor blackColor];
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


#pragma mark - Control Methods

// Custom implementation of the setter for the 'checked' property.
- (void)setChecked:(BOOL)checked
{
    if (checked != _checked)
    {
        _checked = checked;
        
        // Flag ourself as needing to be redrawn.
        [self setNeedsDisplay];
        
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }
}


//  Sends action messages for the given control events along with the UIEvent which triggered them.
//  UIControl provides the -sendActionsForControlEvents: method to send action
//  messages associated with controlEvents.  A limitation of
//  -sendActionsForControlEvents is that it does not include the UIEvent that
//  triggered the controlEvents with the action messages.
//
//  AccessoryViewController and CustomAccessoryViewController rely on receiving
//  the underlying UIEvent when their associated IBActions are invoked.
//  This method functions identically to -sendActionsForControlEvents:
//  but accepts a UIEvent that is sent with the action messages.
- (void)sendActionsForControlEvents:(UIControlEvents)controlEvents withEvent:(UIEvent*)event
{
    NSSet *allTargets = [self allTargets];
    
    for (id target in allTargets)
    {
        NSArray *actionsForTarget = [self actionsForTarget:target forControlEvent:controlEvents];
        
        // Actions are returned as NSString objects, where each string is the
        // selector for the action.
        for (NSString *action in actionsForTarget)
        {
            SEL selector = NSSelectorFromString(action);
            [self sendAction:selector to:target forEvent:event];
        }
    }
}


//  If you override one of the touch event callbacks, you should override all of them.
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}


//  If you override one of the touch event callbacks, you should override all of them.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
}


//  This is the touch callback we are interested in.  If there is a touch inside
//  our bounds, toggle our checked state and notify our target of the change.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[touches anyObject] tapCount] == 1)
    {
        // Toggle our state.
        self.checked = !self.checked;
        
        // Notify our target (if we have one) of the change.
        [self sendActionsForControlEvents:UIControlEventValueChanged withEvent:event];
    }
}


//  If you override one of the touch event callbacks, you should override all of them.
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
}


#pragma mark -
// If you implement a custom control, you should put in the extra work to
// make it accessible.  Your users will appreciate it.
#pragma mark Accessibility


//  Declare that this control is accessible element to assistive applications.
- (BOOL)isAccessibilityElement
{
    return YES;
}


// Note: accessibilityHint and accessibilityLabel should be configured
// elsewhere because this control does not know its purpose as it relates to the program as a whole.
- (UIAccessibilityTraits)accessibilityTraits
{
    // Always combine our accessibilityTraits with the super's
    // accessibilityTraits
    return super.accessibilityTraits | UIAccessibilityTraitButton;
}


- (NSString*)accessibilityValue
{
    return self.checked ? @"Enabled" : @"Disabled";
}

@end
