/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The view controller responsible for showing the location a CKRecord photo was taken.
 */

@import UIKit;
@import CoreLocation;

@interface APLMapViewController : UIViewController

@property (nonatomic, strong) CLLocation *location;

@end