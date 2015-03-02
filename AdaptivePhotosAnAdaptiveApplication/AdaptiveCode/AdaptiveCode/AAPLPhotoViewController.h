/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view controller that shows a photo and its metadata.
 */

@import UIKit;

@class AAPLPhoto;

@interface AAPLPhotoViewController : UIViewController

@property (strong, nonatomic) AAPLPhoto *photo;

@end
