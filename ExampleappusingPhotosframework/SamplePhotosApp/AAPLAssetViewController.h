/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller displaying an asset full screen.
 */

@import UIKit;
@import Photos;


@interface AAPLAssetViewController : UIViewController

@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, strong) PHAssetCollection *assetCollection;

@end
