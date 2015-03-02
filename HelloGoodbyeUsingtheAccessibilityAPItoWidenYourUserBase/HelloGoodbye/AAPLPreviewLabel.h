/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A custom label that appears on the Preview tab in the profile view controller.
  
 */

@import UIKit;

@class AAPLPreviewLabel;

@protocol AAPLPreviewLabelDelegate <NSObject>

- (void)didActivatePreviewLabel:(AAPLPreviewLabel *)previewLabel;

@end

@interface AAPLPreviewLabel : UILabel

@property (nonatomic, weak) id<AAPLPreviewLabelDelegate> delegate;

@end
