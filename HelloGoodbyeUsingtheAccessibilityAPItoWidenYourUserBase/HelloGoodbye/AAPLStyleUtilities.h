/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A collection of methods related to the look and feel of the application.
  
 */

@import UIKit;

@interface AAPLStyleUtilities : NSObject

+ (UIColor *)foregroundColor;
+ (UIColor *)overlayColor;
+ (UIColor *)cardBorderColor;
+ (UIColor *)cardBackgroundColor;
+ (UIColor *)detailColor;
+ (UIColor *)detailOnOverlayColor;
+ (UIColor *)detailOnOverlayPlaceholderColor;
+ (UIColor *)previewTabLabelColor;
+ (CGFloat)overlayCornerRadius;
+ (CGFloat)overlayMargin;
+ (CGFloat)contentVerticalMargin;
+ (CGFloat)contentHorizontalMargin;
+ (UIImage *)overlayRoundedRectImage;
+ (UIButton *)overlayRoundedRectButton;
+ (UIFont *)standardFont;
+ (UIFont *)largeFont;
+ (UILabel *)standardLabel;
+ (UILabel *)detailLabel;

@end
