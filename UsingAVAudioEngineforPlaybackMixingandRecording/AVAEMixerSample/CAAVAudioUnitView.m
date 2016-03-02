/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This subclass of UIView adds rounded corners to the view
*/

#import "CAAVAudioUnitView.h"
#define kRoundedCornerRadius    10

@implementation CAAVAudioUnitView

- (void)setNeedsLayout
{
    [super setNeedsLayout];
    
    UIBezierPath *fillPath = [UIBezierPath bezierPathWithRoundedRect: self.bounds byRoundingCorners:(UIRectCorner)(UIRectCornerAllCorners) cornerRadii:CGSizeMake(kRoundedCornerRadius, kRoundedCornerRadius)];
    
    CAShapeLayer *pathLayer = [[CAShapeLayer alloc] init];
    pathLayer.path = fillPath.CGPath;
    pathLayer.frame = fillPath.bounds;
    
    self.layer.mask = pathLayer;
}

@end
