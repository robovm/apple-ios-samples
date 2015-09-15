/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Coordinates the tableviews and element data sources. It also responds to changes of selection in the table view and provides the cells.
*/


#import "ElementsTableViewController.h"
#import "AtomicElementViewController.h"


@implementation ElementsTableViewController

- (void)setDataSource:(id<ElementsDataSource,UITableViewDataSource>)dataSource {
    
    // retain the data source
    _dataSource = dataSource;
    
    // set the title, and tab bar images from the dataSource
    // object. These are part of the ElementsDataSource Protocol
    self.title = [_dataSource name];
    self.tabBarItem.image = [_dataSource tabBarImage];
    
    // set the long name shown in the navigation bar
    self.navigationItem.title = [_dataSource navigationBarName];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.tableView.sectionIndexMinimumDisplayRowCount = 10;
    
    self.tableView.delegate = self;
	self.tableView.dataSource = self.dataSource;
    
    // create a custom navigation bar button and set it to always say "back"
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = @"Back";
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
}


#pragma mark - UITableViewDelegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"showDetail"]) {
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        
        // find the right view controller
        AtomicElement *element = [self.dataSource atomicElementForIndexPath:selectedIndexPath];
        AtomicElementViewController *viewController =
            (AtomicElementViewController *)segue.destinationViewController;
        
        // hide the bottom tabbar when we push this view controller
        viewController.hidesBottomBarWhenPushed = YES;
        
        // pass the element to this detail view controller
        viewController.element = element;
    }
}

@end
