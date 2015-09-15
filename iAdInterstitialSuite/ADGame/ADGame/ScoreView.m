/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A CAShapeLayer backed view to display the current score
*/

#import "ScoreView.h"
@import QuartzCore;


// We use a subclass of CAShapeLayer so that the path will animate when changed.
// Because UIView only allows certain animation keys to animate, we can't do this via
// the other means usually reserved for doing this, such as the layer's actions dictionary
// or the delegate's -actionForLayer:forKey: method.
@interface MyCAShapeLayer : CAShapeLayer

@end

@implementation MyCAShapeLayer

- (id<CAAction>)actionForKey:(NSString *)key {
    if ([key isEqualToString:@"path"]) {
        return [CABasicAnimation animationWithKeyPath:@"path"];
    }
    else {
        return [super actionForKey:key];
    }
}

@end


@interface ScoreView ()

@property (weak, nonatomic, readonly) CAShapeLayer *shapeLayer;

@end


@implementation ScoreView

    CGGradientRef top;
    CGGradientRef left;
    CGGradientRef bottom;
    CGGradientRef right;

+ (Class)layerClass {
    return [MyCAShapeLayer class];
}

CGGradientRef CreateWhiteToColorGradient(CGFloat r, CGFloat g, CGFloat b) {
    CGFloat colors[] = {
        1.0, 1.0, 1.0, 1.0,
        r, g, b, 1.0,
    };
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, 2);
    CGColorSpaceRelease(rgb);
    return gradient;
}

- (void)commonInit {
    CAShapeLayer *shapeLayer = self.shapeLayer;
    shapeLayer.lineWidth = 3.0;
    shapeLayer.fillRule = kCAFillRuleEvenOdd;
    top = CreateWhiteToColorGradient(1.0, 0.0, 0.0);
    left = CreateWhiteToColorGradient(0.0, 0.0, 1.0);
    bottom = CreateWhiteToColorGradient(0.0, 1.0, 0.0);
    right = CreateWhiteToColorGradient(1.0, 0.625, 0.0);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
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
}

- (CAShapeLayer *)shapeLayer {
    return (CAShapeLayer *)self.layer;
}

- (UIBezierPath *)shape {
    return [UIBezierPath bezierPathWithCGPath:self.shapeLayer.path];
}

- (void)setShape:(UIBezierPath *)shape {
    self.shapeLayer.path = shape.CGPath;
}

- (UIColor *)fillColor {
    return [UIColor colorWithCGColor:self.shapeLayer.fillColor];
}

- (void)setFillColor:(UIColor *)fillColor {
    self.shapeLayer.fillColor = fillColor.CGColor;
}

- (UIColor *)strokeColor {
    return [UIColor colorWithCGColor:self.shapeLayer.strokeColor];
}

- (void)setStrokeColor:(UIColor *)strokeColor; {
    self.shapeLayer.strokeColor = strokeColor.CGColor;
}

@end
