/*
    File: ScoreView.m
Abstract: A CAShapeLayer backed view to display the current score
 Version: 1.2

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

Copyright (C) 2012 Apple Inc. All Rights Reserved.

*/

#import "ScoreView.h"
#import <QuartzCore/QuartzCore.h>

// We use a subclass of CAShapeLayer so that the path will animate when changed.
// Because UIView only allows certain animation keys to animate, we can't do this via
// the other means usually reserved for doing this, such as the layer's actions dictionary
// or the delegate's -actionForLayer:forKey: method.
@interface MyCAShapeLayer : CAShapeLayer
@end

@implementation MyCAShapeLayer

- (id<CAAction>)actionForKey:(NSString *)key
{
    if ([key isEqualToString:@"path"]) {
        return [CABasicAnimation animationWithKeyPath:@"path"];
    } else {
        return [super actionForKey:key];
    }
}

@end

@implementation ScoreView

+ (Class)layerClass
{
    return [MyCAShapeLayer class];
}

CGGradientRef CreateWhiteToColorGradient(CGFloat r, CGFloat g, CGFloat b)
{
    CGFloat colors[] = {
        1.0, 1.0, 1.0, 1.0,
        r, g, b, 1.0,
    };
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, 2);
    CGColorSpaceRelease(rgb);
    return gradient;
}

- (void)commonInit
{
    CAShapeLayer *shapeLayer = self.shapeLayer;
    shapeLayer.lineWidth = 3.0;
    shapeLayer.fillRule = kCAFillRuleEvenOdd;
    top = CreateWhiteToColorGradient(1.0, 0.0, 0.0);
    left = CreateWhiteToColorGradient(0.0, 0.0, 1.0);
    bottom = CreateWhiteToColorGradient(0.0, 1.0, 0.0);
    right = CreateWhiteToColorGradient(1.0, 0.625, 0.0);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // First convert the coordinate system to a unit system.
    // This allows the radial gradients to be ovals if the view is not square.
    // Center will be 0,0, coordinates will be ±1
    CGRect bounds = self.bounds;
    CGContextTranslateCTM(context, bounds.size.width / 2.0, bounds.size.height / 2.0);
    CGContextScaleCTM(context, bounds.size.width / 2.0, bounds.size.height / 2.0);

    // Top
    CGContextSaveGState(context);
    CGContextMoveToPoint(context, 0.0, 0.0);
    CGContextAddLineToPoint(context, -1.0, -1.0);
    CGContextAddLineToPoint(context, 1.0, -1.0);
    CGContextClip(context);
    CGContextDrawRadialGradient(context, top, CGPointZero, 0.0, CGPointZero, 1.0, kCGGradientDrawsBeforeStartLocation);
    CGContextRestoreGState(context);

    // Left
    CGContextSaveGState(context);
    CGContextMoveToPoint(context, 0.0, 0.0);
    CGContextAddLineToPoint(context, -1.0, -1.0);
    CGContextAddLineToPoint(context, -1.0, 1.0);
    CGContextClip(context);
    CGContextDrawRadialGradient(context, left, CGPointZero, 0.0, CGPointZero, 1.0, kCGGradientDrawsBeforeStartLocation);
    CGContextRestoreGState(context);

    // Bottom
    CGContextSaveGState(context);
    CGContextMoveToPoint(context, 0.0, 0.0);
    CGContextAddLineToPoint(context, -1.0, 1.0);
    CGContextAddLineToPoint(context, 1.0, 1.0);
    CGContextClip(context);
    CGContextDrawRadialGradient(context, bottom, CGPointZero, 0.0, CGPointZero, 1.0, kCGGradientDrawsBeforeStartLocation);
    CGContextRestoreGState(context);

    // Left
    CGContextSaveGState(context);
    CGContextMoveToPoint(context, 0.0, 0.0);
    CGContextAddLineToPoint(context, 1.0, -1.0);
    CGContextAddLineToPoint(context, 1.0, 1.0);
    CGContextClip(context);
    CGContextDrawRadialGradient(context, right, CGPointZero, 0.0, CGPointZero, 1.0, kCGGradientDrawsBeforeStartLocation);
    CGContextRestoreGState(context);
}

- (void)dealloc {
    CGGradientRelease(top);
    CGGradientRelease(left);
    CGGradientRelease(bottom);
    CGGradientRelease(right);
    [super dealloc];
}

- (CAShapeLayer *)shapeLayer
{
    return (CAShapeLayer *)self.layer;
}

- (UIBezierPath *)shape
{
    return [UIBezierPath bezierPathWithCGPath:self.shapeLayer.path];
}

- (void)setShape:(UIBezierPath *)shape
{
    self.shapeLayer.path = shape.CGPath;
}

- (UIColor *)fillColor
{
    return [UIColor colorWithCGColor:self.shapeLayer.fillColor];
}

- (void)setFillColor:(UIColor *)fillColor
{
    self.shapeLayer.fillColor = fillColor.CGColor;
}

- (UIColor *)strokeColor
{
    return [UIColor colorWithCGColor:self.shapeLayer.strokeColor];
}

- (void)setStrokeColor:(UIColor *)strokeColor;
{
    self.shapeLayer.strokeColor = strokeColor.CGColor;
}

@end
