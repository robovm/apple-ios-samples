/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Controller that manages the full tile view of the atomic information, creating the reflection, and the flipping of the tile.
*/

@import UIKit;

@class AtomicElement;

@interface AtomicElementViewController : UIViewController

@property (nonatomic,strong) AtomicElement *element;

- (void)flipCurrentView;

@end
