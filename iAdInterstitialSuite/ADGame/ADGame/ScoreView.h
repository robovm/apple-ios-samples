/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A CAShapeLayer backed view to display the current score
*/

@interface ScoreView : UIView

@property (nonatomic, strong)   UIColor *fillColor;
@property (nonatomic, strong)   UIColor *strokeColor;
@property (nonatomic, copy)     UIBezierPath *shape;

@end
