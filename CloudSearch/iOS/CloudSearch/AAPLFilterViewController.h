/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Table view for choosing the file extension to filter.
 */

#import <UIKit/UIKit.h>

@protocol AAPLFilterViewControllerDelegate;

@interface AAPLFilterViewController : UITableViewController

@property (nonatomic, weak, readwrite) id<AAPLFilterViewControllerDelegate> filterDelegate;
@property (nonatomic, strong) NSIndexPath *extensionToFilter;

@end


#pragma mark -

// protocol used to inform our parent table view controller to update its table if the given record has changed
@protocol AAPLFilterViewControllerDelegate <NSObject>

@required
- (void)filterViewController:(AAPLFilterViewController *)viewController didSelectExtension:(NSIndexPath *)extension;

@end
