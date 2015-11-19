/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UITableViewController that allows for the selection of a CLCoordinate2D.
 */

@import UIKit;
@import CoreLocation;

typedef NS_ENUM(NSInteger, CoordinateSelectorLastSelectedType)
{
    CoordinateSelectorLastSelectedTypeSearch = 1,
    CoordinateSelectorLastSelectedTypeCurrent,
    CoordinateSelectorLastSelectedTypeUndefined,
} ;

// this class contains a list of names and associated Coordinates as well as allowing
// for the selection of a custom Coordinate it vends the users selection through
// the 4 selected properties..
//
@interface CoordinateSelectorTableViewController : UITableViewController <UITextFieldDelegate, CLLocationManagerDelegate>

@property (readonly) CLLocationCoordinate2D selectedCoordinate;
@property (readonly) CoordinateSelectorLastSelectedType selectedType;
@property (readonly) NSString *selectedName;

@end
