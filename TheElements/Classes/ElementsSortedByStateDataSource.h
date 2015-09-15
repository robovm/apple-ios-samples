/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Provides the table view data for the elements sorted by their standard physical state.
*/

@import UIKit;
#import "ElementsDataSourceProtocol.h"

@interface ElementsSortedByStateDataSource : NSObject <UITableViewDataSource,ElementsDataSource> {
}

@end
 