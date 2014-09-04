/*
     File: BulbView.m
 Abstract: View that hosts the custom CALayer subclass. Since the view hosts the layer in this case, it executes the animations when explicit animations are the enabled animation trigger. 
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

#import "BulbView.h"
#import "BulbLayer.h"
#import "Defines.h"

@implementation BulbView

+(Class)layerClass {
    return [BulbLayer class];
}

-(id)init {
    if( self = [super init] ) {
        
        // define a default frame.
        self.image = [UIImage imageNamed:@"bulb.png"];
        self.frame = CGRectMake( 0, 0, self.image.size.width, self.image.size.height );

        // general bulb initializer
        [self generalInit];
    }
    return self;
}

// BulbView must be initialized via initWithFrame:.
-(id)initWithFrame:(CGRect)frame {
    if( ( self = [super initWithFrame:frame] ) ) {

        // general bulb initializer
        [self generalInit];
    }
    return self;
}

// General bulb initialization.
-(void)generalInit {
    NSLog(@"%s",__PRETTY_FUNCTION__);
    
    // Grab the bulb image and log whether or not we succeeded to load the image.
    self.image = [UIImage imageNamed:@"bulb.png"];
    NSLog(@"image==nil? %@",_image==nil?@"yes":@"no");
    
    // Get our layer to do a small custom configuration.
    CALayer* layer = [self layer];
    // By setting opaque to NO it defines our backing store to include an alpha channel.
    layer.opaque = NO;
    
    // The default bulb color is red.
    [self setColor:[UIColor redColor]];
}


// When a bulb color is set we define the color components used during our custom animation
-(void)setColor:(UIColor*)color {
    NSLog(@"%s",__PRETTY_FUNCTION__);
    _color = color;
    CGColorRef cgColor = color.CGColor;
    const CGFloat* colors = CGColorGetComponents( cgColor );
    self.red = colors[0] * 255.0;
    self.green = colors[1] * 255.0;
    self.blue = colors[2] * 255.0;
    NSLog(@"%s red: %f, green: %f, blue: %f",__PRETTY_FUNCTION__,self.red,self.green,self.blue );
    
}

// Toggle the On/Off state of the bulb. This triggers our custom animation.
-(void)setOn:(BOOL)on animated:(BOOL)animated {
    NSLog(@"%s",__PRETTY_FUNCTION__);
    if( !animated ) {
        ((BulbLayer*)self.layer).brightness = ((int)on) * 255;
        return;
    }
    if( on ) {
        if( self.on ) return;
        _on = on;
#if ANIMATION_TRIGGER_EXPLICIT
        [self animateFrom:0.0 to:255.0];
#endif
    } else {
        if( !self.on ) return; 
        _on = on;
#if ANIMATION_TRIGGER_EXPLICIT
        [self animateFrom:255.0 to:0.0];
#endif
    }
    // Set the model layer's brightness to the final value.
    
#if ANIMATION_TRIGGER_EXPLICIT
    // For explicit animations, disable implicit animations to avoid triggering the default action.
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
#endif
    ((BulbLayer*)self.layer).brightness = ((int)on) * 255;
#if ANIMATION_TRIGGER_EXPLICIT
    [CATransaction commit];
#endif
}

// Executes the explicit animation.
-(void)animateFrom:(CGFloat)from to:(CGFloat)to {
    NSLog(@"%s",__PRETTY_FUNCTION__);
#if ANIMATION_TYPE_KEYFRAME
    // Create a basic interpolation for "briteness" animation
    CAKeyframeAnimation *theAnimation = [CAKeyframeAnimation animation];
    theAnimation.duration = 1.0;
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
    CABasicAnimation* theAnimation = [CABasicAnimation animation];
    theAnimation.duration = 1.0;
    theAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    theAnimation.fromValue = @(from);
    theAnimation.toValue = @(to);
#endif
    [self.layer addAnimation:theAnimation forKey:@"brightness"];
}

// Unused. Layer delegate method for drawing is used instead.
-(void)drawRect:(CGRect)rect {
    NSLog(@"%s",__PRETTY_FUNCTION__);
}

// Layer delegate method for custom drawing.
// Color the bulb background and then draw our bulb image on top.
-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    NSLog(@"%s",__PRETTY_FUNCTION__);

    // Get the current state of the bulb's "brightness"
    // Core Animation is animating this value on our behalf.
    CGFloat brightness = ((BulbLayer*)layer).brightness;
    NSLog(@"brightness: %f",brightness);
    
    // Calculate the bulbs current color (via RGB components) based on
    // the bulb's current "brightness".
    CGFloat redDiff = 255 - self.red;
    CGFloat greenDiff = 255 - self.green;
    CGFloat blueDiff = 255 - self.blue;
    CGFloat curRed = self.red + redDiff * ( brightness / 255.0 );
    CGFloat curGreen = self.green + greenDiff * ( brightness / 255.0 );
    CGFloat curBlue = self.blue + blueDiff * ( brightness / 255.0 );
    NSLog(@"curRed: %f, curGreen: %f, curBlue: %f",curRed,curGreen,curBlue);
    
    // Start an offscreen graphics context
    UIGraphicsBeginImageContextWithOptions( _image.size, YES, 1.0f );
    self.currentContext = UIGraphicsGetCurrentContext();
    CGRect imageRect = CGContextGetClipBoundingBox( self.currentContext );

    // Fill the context with our bulbs current color.
    UIColor* color = [UIColor colorWithRed:curRed/255.0 green:curGreen/255.0 blue:curBlue/255.0 alpha:1.0];
    [color set];
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGContextGetClipBoundingBox( self.currentContext )];
    [path fill];
    
    // Draw the bulb image into the context.
    CGContextDrawImage( self.currentContext, imageRect, _image.CGImage );
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    NSLog(@"image==nil? %@",image==nil?@"yes":@"no");
    UIGraphicsEndImageContext();
    
    // Define the colors that will be masked out of the final image.
    const CGFloat maskingColors[6] = { 248.0, 255.0, 248.0, 255.0, 248.0, 255.0 };

    // Apply the mask and create the final image.
    CGImageRef finalImage = CGImageCreateWithMaskingColors( image.CGImage, maskingColors );
    NSLog(@"bulbMask2==NULL? %@",finalImage==NULL?@"yes":@"no");

    // Get our context's rect and draw the final bulb image into it.
    CGRect contextRect = CGContextGetClipBoundingBox( context );
    NSLog(@"contextRect: %@",NSStringFromCGRect( contextRect ) );
    CGContextDrawImage( context, contextRect, finalImage );
    
    // Release the final image. 
    CGImageRelease( finalImage );
}

// Touch handler for the bulb. Toggles the On/Off state.
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [self setOn:!self.on animated:YES];
}

@end
