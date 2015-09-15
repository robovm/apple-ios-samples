/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Displays the Atomic Element information in a large format tile.
*/

@import UIKit;

@class AtomicElement;
@class AtomicElementViewController;

@interface AtomicElementView : UIView

@property (nonatomic,strong) AtomicElement *element;
@property (nonatomic, weak) AtomicElementViewController *viewController;

+ (CGSize)preferredViewSize;
- (UIImage *)reflectedImageRepresentationWithHeight:(NSUInteger)height;

@end
