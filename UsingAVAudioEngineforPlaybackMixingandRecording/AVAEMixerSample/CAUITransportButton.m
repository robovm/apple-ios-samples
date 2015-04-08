/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This UIButton subclass programatically draws a transport button with a particular drawing style.
                It features a fill color that can be an accent color.
                If the button has the recordEnabledButtonStyle, it pulses on and off.
                 
                These buttons resize themselves dynamically at runtime so that their bounds is a minimum of 44 x 44 pts
                in order to make them easy to press.
                The button image will draw at the original size specified in the storyboard
*/

#import "CAUITransportButton.h"

#define kMinimumButtonSize 24
// #define drawDoubleArrows 1		// uncomment to activate a double arrow drawing style instead of a bar with a single triangle

@implementation CAUITransportButton

#pragma mark - Intialization
- (id) initWithCoder:(NSCoder *) aDecoder {
	self = [super initWithCoder: aDecoder];
	
	if (self) {
		imageRect = self.bounds;
		CGFloat widthDelta = kMinimumButtonSize - self.bounds.size.width;
		CGFloat heightDelta= kMinimumButtonSize - self.bounds.size.height;
		
		if (widthDelta > 0 || heightDelta > 0) {
			// update the frame
			CGRect bounds = CGRectMake(0, 0, widthDelta > 0 ? kMinimumButtonSize : imageRect.size.width, heightDelta > 0 ? kMinimumButtonSize : imageRect.size.height);
			CGRect frame  = CGRectMake(widthDelta > 0 ? roundf(self.frame.origin.x - (widthDelta / 2)) : self.frame.origin.x,
									   heightDelta > 0? roundf(self.frame.origin.y - (heightDelta/ 2)) : self.frame.origin.y,
									   bounds.size.width, bounds.size.height);
			
			self.frame = frame;
			self.bounds = bounds;
			
		}
	}
	return self;
}

- (id) initWithFrame: (CGRect) frame {
	if (self = [super initWithFrame:frame]) {
		imageRect = self.bounds;
		CGFloat widthDelta = kMinimumButtonSize - frame.size.width;
		CGFloat heightDelta= kMinimumButtonSize - frame.size.height;
		
		if (widthDelta > 0 || heightDelta > 0) {
			// update the frame
			CGRect bounds = CGRectMake(0, 0, widthDelta > 0 ? kMinimumButtonSize : imageRect.size.width, heightDelta > 0 ? kMinimumButtonSize : imageRect.size.height);
			CGRect theFrame  = CGRectMake(widthDelta > 0 ? roundf(self.frame.origin.x - (widthDelta / 2)) : self.frame.origin.x,
									   heightDelta > 0? roundf(self.frame.origin.y - (heightDelta/ 2)) : self.frame.origin.y,
									   bounds.size.width, bounds.size.height);
			
			self.frame  = theFrame;
			self.bounds = bounds;
		}
	}
	return self;
}

+ (Class) layerClass {
	return [CAShapeLayer class];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (event.type == UIEventTypeTouches) {
		UIColor *tempColor = [UIColor colorWithCGColor: ((CAShapeLayer *)self.layer).fillColor];
		((CAShapeLayer *)self.layer).fillColor = [tempColor colorWithAlphaComponent: .5].CGColor;
	}
	
	[super touchesBegan:touches withEvent: event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (event.type == UIEventTypeTouches)
		((CAShapeLayer *)self.layer).fillColor = fillColor;
	
	[super touchesEnded:touches withEvent: event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	if (event.type == UIEventTypeTouches)
	((CAShapeLayer *)self.layer).fillColor = fillColor;

	[super touchesEnded:touches withEvent: event];
}

double toRadians(double degrees) {
    return (degrees * M_PI)/180.0;
}

#pragma mark - Property methods
/* We don't do any actual drawing in this class. This method sets the properties of the layer object based on the type of button we are drawing */
- (void) setDrawingStyle:(CAUITransportButtonStyle) style {
	if (drawingStyle != style) {		
		drawingStyle = style;
		CGPathRef path = [self newPathRefForStyle: style];
		((CAShapeLayer *)self.layer).path = path;
		CGPathRelease(path);
		
		self.backgroundColor = [UIColor clearColor];
		
		if (style == recordEnabledButtonStyle) {
			[UIView animateWithDuration:1 delay:0 options: UIViewAnimationOptionCurveLinear
							 animations:^{
					((CAShapeLayer *)self.layer).strokeColor = fillColor;
					((CAShapeLayer *)self.layer).fillColor = fillColor;
					((CAShapeLayer *)self.layer).lineWidth = .5;
					[self flash];
				}		completion:NULL];
			
		} else if (style == recordButtonStyle) {
			[((CAShapeLayer *)self.layer) removeAllAnimations];
			[UIView animateWithDuration:1 delay:0 options: UIViewAnimationOptionCurveLinear
							 animations:^{
				((CAShapeLayer *)self.layer).strokeColor = [UIColor clearColor].CGColor;
				((CAShapeLayer *)self.layer).fillColor = fillColor;
				((CAShapeLayer *)self.layer).lineWidth = 0;
			}			completion:nil];
		}
		[self setNeedsDisplay];
	}
}

- (CAUITransportButtonStyle) drawingStyle {
	return drawingStyle;
}

- (void) setFillColor:(CGColorRef) color {
	CGColorRetain(color);
	CGColorRelease(fillColor);
	fillColor = color;
	((CAShapeLayer *)self.layer).fillColor = color;
}

- (CGColorRef) fillColor {
	return fillColor;
}

#pragma mark - Drawing methods
- (void) flash {
	UIColor *color = [[UIColor colorWithCGColor: fillColor] colorWithAlphaComponent: .2];
	[CATransaction begin];
	CABasicAnimation *strokeAnim = [CABasicAnimation animationWithKeyPath:@"fillColor"];
    strokeAnim.fromValue         = (id) ((CAShapeLayer *)self.layer).fillColor;
    strokeAnim.toValue           = (id) color.CGColor;
    strokeAnim.duration          = 2.0;
    strokeAnim.repeatCount       = 0;
    strokeAnim.autoreverses      = YES;
	[CATransaction setCompletionBlock: ^{
		if (drawingStyle == recordEnabledButtonStyle)
			[self flash];
	}];
    [((CAShapeLayer *)self.layer) addAnimation:strokeAnim forKey:@"animateStrokeColor"];
	[CATransaction commit];
}

- (CGPathRef) newPathRefForStyle: (CAUITransportButtonStyle) style {
	CGPathRef path = nil;
	CGFloat size = MIN(imageRect.size.width, imageRect.size.height);
	
	switch (style) {
		case rewindButtonStyle:
		{
			CGMutablePathRef tempPath = CGPathCreateMutable();
#ifdef drawDoubleArrows
			CGFloat height = size * 0.613;
			CGFloat width  = size;
			CGFloat radius = (size * .0631)/2;
#else
			CGFloat height = size * .857;
			CGFloat width  = size * .699;
			CGFloat radius = (size * .026)/2;
#endif
			CGFloat yOffset = roundf((imageRect.size.height - height)/2);

			height = roundf(height);

#ifdef drawDoubleArrows
			// first arrow
			CGPathAddArc(tempPath, NULL, radius, yOffset + height/2, radius, toRadians(120), toRadians(240), NO);
			CGPathAddArc(tempPath, NULL, .5 * width - radius, yOffset + radius, radius, toRadians(240), toRadians(0), NO);
			CGPathAddArc(tempPath, NULL, .5 * width - radius, yOffset + height - radius, radius, toRadians(0), toRadians(120), NO);
			CGPathCloseSubpath(tempPath);
			
			// second arrow
			CGPathMoveToPoint(tempPath, NULL, .5*size, yOffset + height/2);
			CGPathAddArc(tempPath, NULL, .5*size + radius, yOffset + height/2, radius, toRadians(180), toRadians(240), NO);
			CGPathAddArc(tempPath, NULL, width - radius, yOffset + radius, radius, toRadians(240), toRadians(0), NO);
			CGPathAddArc(tempPath, NULL, width - radius, yOffset + height - radius, radius, toRadians(0), toRadians(120), NO);
			CGPathAddArc(tempPath, NULL, .5*size + radius, yOffset + height/2, radius, toRadians(120), toRadians(180), NO);
#else			
			CGFloat xOffset = 0.062 * size;
			CGPathAddRoundedRect(tempPath, NULL, CGRectMake(0, yOffset, xOffset, height), radius, radius);
			
			radius  = (size * .0631)/2;
			xOffset += .006 * size;
			
			CGPathAddArc(tempPath, NULL, xOffset + radius, yOffset + height/2, radius, toRadians(120), toRadians(240), NO);
			CGPathAddArc(tempPath, NULL, xOffset + width - radius, yOffset + radius, radius, toRadians(240), toRadians(0), NO);
			CGPathAddArc(tempPath, NULL, xOffset + width - radius, yOffset + height - radius, radius, toRadians(0), toRadians(120), NO);
#endif
			CGPathCloseSubpath(tempPath);

			path = tempPath;
		}
			break;
		case pauseButtonStyle:
		{
			CGMutablePathRef tempPath = CGPathCreateMutable();
			CGFloat height = size * 0.857;
			CGFloat width  = size * .7452;
			CGFloat barWidth = size * .2776;
			CGFloat xOffset = roundf((imageRect.size.width - width)/2);
			CGFloat	yOffset = roundf((imageRect.size.height - height)/2);
			CGFloat radius = (size * 0.0397)/2;
			
			height = roundf(height);
			
			CGPathAddRoundedRect(tempPath, NULL, CGRectMake(xOffset, yOffset, barWidth, height), radius, radius);
			CGPathAddRoundedRect(tempPath, NULL, CGRectMake(roundf(imageRect.size.width - xOffset - barWidth), yOffset, barWidth, height), radius, radius);
			
			path = tempPath;
		}
			break;
		case playButtonStyle:
		{
			CGMutablePathRef tempPath = CGPathCreateMutable();
			CGFloat height = size * .857;
			CGFloat width  = size * .6538;
			CGFloat xOffset = roundf((imageRect.size.width - width)/2);
			CGFloat yOffset = roundf((imageRect.size.height - height)/2);
			CGFloat radius  = (size * .0631)/2;
			
			height = roundf(height);
			
			CGPathAddArc(tempPath, NULL, xOffset + radius, yOffset + radius, radius, toRadians(180), toRadians(300), NO);
			CGPathAddArc(tempPath, NULL, xOffset + width - radius, yOffset + height/2, radius, toRadians(300), toRadians(60), NO);
			CGPathAddArc(tempPath, NULL, xOffset + radius, yOffset + height - radius, radius, toRadians(60), toRadians(180), NO);
			CGPathCloseSubpath(tempPath);
			path = tempPath;
		}
			break;
		case recordButtonStyle:
		case recordEnabledButtonStyle:
		{
			size *= .7825;
			CGRect elipseRect = CGRectMake((imageRect.size.width - size)/2, (imageRect.size.height - size)/2, size, size);
			
			path = CGPathCreateWithEllipseInRect(elipseRect, NULL);
		}
			break;
        case stopButtonStyle: {
            CGMutablePathRef tempPath = CGPathCreateMutable();
            CGFloat height = size * 0.857;
            CGFloat offset = roundf((imageRect.size.width - height)/2);
            CGFloat radius = (size * 0.0397)/2;
            
            height = roundf(height);
            
            CGPathAddRoundedRect(tempPath, NULL, CGRectMake(offset, offset, height, height), radius, radius);
            
            path = tempPath;
        }
	}
	return path;
}

@end
