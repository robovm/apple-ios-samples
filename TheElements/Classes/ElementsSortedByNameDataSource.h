/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Provides the table view data for the elements sorted by name.
*/

@import UIKit;

#import "ElementsDataSourceProtocol.h"

@interface ElementsSortedByNameDataSource : NSObject <UITableViewDataSource, ElementsDataSource> {
}

@end
