/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The application's root view controller.
*/

@import UIKit;

@interface RootViewController : UIViewController

// The displayed UIColor.  If the app was launched with a valid
// URL, this will be set by the AppDelegate to the decoded color.
@property (nonatomic, strong) UIColor *selectedColor;

// Outlet for the label above the displayed URL.
// The AppDelegate updates the text of this label to notify the user
// that the app was launched from a URL request.
@property (nonatomic, weak) IBOutlet UILabel *urlFieldHeader;

@end
