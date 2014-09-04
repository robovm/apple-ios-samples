/*
     File: APLDecorationView.m
 Abstract: n/a
  Version: 1.3
 
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

#import "APLDecorationView.h"

@interface APLDecorationView ()
@property (nonatomic, strong) UIView *attachmentPointView;
@property (nonatomic, strong) UIView *attachedView;
@property (nonatomic, readwrite) CGPoint attachmentOffset;
//! Array of CALayer objects, each with the contents of an image
//! for a dash.
@property (nonatomic, strong) NSMutableArray *attachmentDecorationLayers;
@property (nonatomic, weak) IBOutlet UIImageView *centerPointView;
@property (nonatomic, weak) UIImageView *arrowView;
@end


@implementation APLDecorationView

//| ----------------------------------------------------------------------------
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"BackgroundTile"]];
    }
    return self;
}


//| ----------------------------------------------------------------------------
- (void)dealloc
{
    [self.attachmentPointView removeObserver:self forKeyPath:@"center"];
    [self.attachedView removeObserver:self forKeyPath:@"center"];
}


//| ----------------------------------------------------------------------------
//! Draws an arrow with a given @a length anchored at the center of the receiver,
//! that points in the direction given by @a angle.
//
- (void)drawMagnitudeVectorWithLength:(CGFloat)length angle:(CGFloat)angle color:(UIColor*)arrowColor forLimitedTime:(BOOL)temporary
{
    if (!self.arrowView)
    // First time initialization.
    {
        UIImage *arrowImage = [[UIImage imageNamed:@"Arrow"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:arrowImage];
        arrowImageView.bounds = CGRectMake(0, 0, arrowImage.size.width, arrowImage.size.height);
        arrowImageView.contentMode = UIViewContentModeRight;
        arrowImageView.clipsToBounds = YES;
        arrowImageView.layer.anchorPoint = CGPointMake(0.0, 0.5);
        
        [self addSubview:arrowImageView];
        [self sendSubviewToBack:arrowImageView];
        self.arrowView = arrowImageView;
    }

    self.arrowView.bounds = CGRectMake(0, 0, length, self.arrowView.bounds.size.height);
    self.arrowView.transform = CGAffineTransformMakeRotation(angle);
    self.arrowView.tintColor = arrowColor;
    self.arrowView.alpha = 1;
    
    if (temporary)
        [UIView animateWithDuration:1.0 animations:^{
            self.arrowView.alpha = 0;
        }];
}


//| ----------------------------------------------------------------------------
//! Draws a dashed line between @a attachmentPointView and @a attachedView
//! that is updated as either view moves.
//
- (void)trackAndDrawAttachmentFromView:(UIView*)attachmentPointView toView:(UIView*)attachedView withAttachmentOffset:(CGPoint)attachmentOffset
{
    if (!self.attachmentDecorationLayers)
    // First time initialization.
    {
        self.attachmentDecorationLayers = [NSMutableArray arrayWithCapacity:4];
        for (NSUInteger i=0; i<4; i++)
        {
            UIImage *dashImage = [UIImage imageNamed:[NSString stringWithFormat:@"DashStyle%i", (i % 3) + 1]];
            
            CALayer *dashLayer = [CALayer layer];
            dashLayer.contents = (__bridge id)(dashImage.CGImage);
            dashLayer.bounds = CGRectMake(0, 0, dashImage.size.width, dashImage.size.height);
            dashLayer.anchorPoint = CGPointMake(0.5, 0);
            
            [self.layer insertSublayer:dashLayer atIndex:0];
            [self.attachmentDecorationLayers addObject:dashLayer];
        }
    }
    
    // A word about performance.
    // Tracking changes to the properties of any id<UIDynamicItem> involved in
    // a simulation incurs a performance cost.  You will receive a callback
    // during each step in the simulation in which the tracked item is not at
    // rest.  You should therefore strive to make your callback code as
    // efficient as possible.
    
    [self.attachmentPointView removeObserver:self forKeyPath:@"center"];
    [self.attachedView removeObserver:self forKeyPath:@"center"];
    
    self.attachmentPointView = attachmentPointView;
    self.attachedView = attachedView;
    self.attachmentOffset = attachmentOffset;
    
    // Observe the 'center' property of both views to know when they move.
    [self.attachmentPointView addObserver:self forKeyPath:@"center" options:0 context:NULL];
    [self.attachedView addObserver:self forKeyPath:@"center" options:0 context:NULL];
    
    [self setNeedsLayout];
}


//| ----------------------------------------------------------------------------
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.arrowView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    if (self.centerPointView)
        self.centerPointView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    if (self.attachmentDecorationLayers)
    {
        // Here we adjust the line dash pattern visualizing the attachement
        // between attachmentPointView and attachedView to account for a change
        // in the position of either.
        
        const NSUInteger MaxDashes = self.attachmentDecorationLayers.count;
        
        CGPoint attachmentPointViewCenter = CGPointMake(self.attachmentPointView.bounds.size.width/2, self.attachmentPointView.bounds.size.height/2);
        attachmentPointViewCenter = [self.attachmentPointView convertPoint:attachmentPointViewCenter toView:self];
        CGPoint attachedViewAttachmentPoint = CGPointMake(self.attachedView.bounds.size.width/2 + self.attachmentOffset.x, self.attachedView.bounds.size.height/2 + self.attachmentOffset.y);
        attachedViewAttachmentPoint =  [self.attachedView convertPoint:attachedViewAttachmentPoint toView:self];
        
        CGFloat distance = sqrtf( powf(attachedViewAttachmentPoint.x-attachmentPointViewCenter.x, 2.0) +
                                 powf(attachedViewAttachmentPoint.y-attachmentPointViewCenter.y, 2.0) );
        CGFloat angle = atan2( attachedViewAttachmentPoint.y-attachmentPointViewCenter.y,
                              attachedViewAttachmentPoint.x-attachmentPointViewCenter.x );
        
        NSUInteger requiredDashes = 0;
        CGFloat d = 0.0f;
        
        // Depending on the distance between the two views, a smaller number of
        // dashes may be needed to adequately visualize the attachment.  Starting
        // with a distance of 0, we add the length of each dash until we exceed
        // 'distance' computed previously or we use the maximum number of allowed
        // dashes, 'MaxDashes'.
        while (requiredDashes < MaxDashes)
        {
            CALayer *dashLayer = self.attachmentDecorationLayers[requiredDashes];
            
            if (d + dashLayer.bounds.size.height < distance) {
                d += dashLayer.bounds.size.height;
                dashLayer.hidden = NO;
                requiredDashes++;
            } else
                break;
        }
        
        // Based on the total length of the dashes we previously determined were
        // necessary to visualize the attachment, determine the spacing between
        // each dash.
        CGFloat dashSpacing = (distance - d) / (requiredDashes + 1);
        
        // Hide the excess dashes.
        for (; requiredDashes < MaxDashes; requiredDashes++)
            [self.attachmentDecorationLayers[requiredDashes] setHidden:YES];
        
        // Disable any animations.  The changes must take full effect immediately.
        [CATransaction begin];
        [CATransaction setAnimationDuration:0];
        
        // Each dash layer is positioned by altering its affineTransform.  We
        // combine the position of rotation into an affine transformation matrix
        // that is assigned to each dash.
        CGAffineTransform transform = CGAffineTransformMakeTranslation(attachmentPointViewCenter.x, attachmentPointViewCenter.y);
        transform = CGAffineTransformRotate(transform, angle - M_PI/2);
        
        for (NSUInteger drawnDashes = 0; drawnDashes < requiredDashes; drawnDashes++)
        {
            CALayer *dashLayer = self.attachmentDecorationLayers[drawnDashes];
            
            transform = CGAffineTransformTranslate(transform, 0, dashSpacing);
            
            [dashLayer setAffineTransform:transform];
            
            transform = CGAffineTransformTranslate(transform, 0, dashLayer.bounds.size.height);
        }
        
        [CATransaction commit];
    }
}


//| ----------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.attachmentPointView || object == self.attachedView)
        [self setNeedsLayout];
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
