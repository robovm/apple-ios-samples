/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    AVAudioUnitView
*/

#import "CAAVAudioUnitView.h"
#define kRoundedCornerRadius    10

@implementation CAAVAudioUnitView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        UIBezierPath *fillPath = [UIBezierPath bezierPathWithRoundedRect: self.bounds byRoundingCorners:(UIRectCorner)(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(kRoundedCornerRadius, kRoundedCornerRadius)];
            
        CAShapeLayer *pathLayer = [[CAShapeLayer alloc] init];
        pathLayer.path = fillPath.CGPath;
        pathLayer.frame = fillPath.bounds;
            
        self.layer.mask = pathLayer;       
    }
    return self;
}

@end
