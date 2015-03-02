/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view controller displaying an asset full screen.
  
 */

@import UIKit;
@import Photos;


@interface AAPLAssetViewController : UIViewController

@property (strong) PHAsset *asset;
@property (strong) PHAssetCollection *assetCollection;

@end
