/*
     File: BulbLayer.m
 Abstract: The custom CALayer subclass which implements a custom implicitly animatable property.
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "BulbLayer.h"
#import "Defines.h"

@implementation BulbLayer

// Needed to support implicit animation of this property.
@dynamic brightness;

// For CALayer subclasses, always support initWithLayer: by copying over custom properties.
-(id)initWithLayer:(id)layer {
    if( ( self = [super initWithLayer:layer] ) ) {
        if ([layer isKindOfClass:[BulbLayer class]]) {
            self.brightness = ((BulbLayer*)layer).brightness;
        }
    }
    return self;
}

// Instruct to Core Animation that a change in the custom "brightness" property should automatically trigger a redraw of the layer.
+(BOOL)needsDisplayForKey:(NSString*)key {
    if( [key isEqualToString:@"brightness"] )
        return YES;
    return [super needsDisplayForKey:key];
}

// Needed to support implicit animation of this property.
// Return the basic animation the implicit animation will leverage.
-(id<CAAction>)actionForKey:(NSString *)event {
    NSLog(@"%s - event: %@",__PRETTY_FUNCTION__,event);
    if( [event isEqualToString:@"brightness"] ) {

#if ANIMATION_TYPE_KEYFRAME
        // Create a basic interpolation for "briteness" animation
        CAKeyframeAnimation *theAnimation = [CAKeyframeAnimation
                                          animationWithKeyPath:event];
        // Hint: the previous value of the property is stored in the presentationLayer
        // Since for implicit animations, the model property is already set to the new value.
        theAnimation.calculationMode = kCAAnimationDiscrete;
        theAnimation.values = @[
                                @(0.0), @(255.0),
                                @(0.0), @(255.0),
                                @(0.0), @(255.0),
                                @(0.0), @(255.0),
                                @(0.0), @(255.0),
                                @(0.0), @(255.0),
                                @(0.0), @(255.0),
                                @(0.0), @(255.0),
                                ];
#else
        // Create a basic interpolation for "briteness" animation
        CABasicAnimation *theAnimation = [CABasicAnimation
                                          animationWithKeyPath:event];
        // Hint: the previous value of the property is stored in the presentationLayer
        // Since for implicit animations, the model property is already set to the new value.
        theAnimation.fromValue = [[self presentationLayer] valueForKey:event];
#endif
        return theAnimation;
    }
    return [super actionForKey:event];
}

@end
