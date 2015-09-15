/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Coordinates the tableviews and element data sources. It also responds to changes of selection in the table view and provides the cells.
*/

@import UIKit;
#import "ElementsDataSourceProtocol.h"

@interface ElementsTableViewController : UITableViewController

@property (nonatomic,strong) id<ElementsDataSource, UITableViewDataSource> dataSource;

@end
