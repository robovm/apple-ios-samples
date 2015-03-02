/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  UITableViewController that Displays a list of CLPlacemarks.
  
 */

#import <UIKit/UIKit.h>

@interface PlacemarksListViewController : UITableViewController

// designated initilizers

// show the coord in the main textField in the cell if YES
- (instancetype)initWithPlacemarks:(NSArray*)placemarks preferCoord:(BOOL)shouldPreferCoord NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPlacemarks:(NSArray*)placemarks;

@end
