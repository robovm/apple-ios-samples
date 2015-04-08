/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Subclass of UINavigationBar that displays a button above the
  navigation bar's contents.
 */

@import UIKit;

@interface CustomNavigationBar : UINavigationBar

//! The button to display above the primary contents of the navigation bar.
@property (nonatomic, strong) UIButton *customButton;

@end
