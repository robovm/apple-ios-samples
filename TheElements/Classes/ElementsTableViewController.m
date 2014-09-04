/*
     File: ElementsTableViewController.m
 Abstract: Coordinates the tableviews and element data sources. It also responds
 to changes of selection in the table view and provides the cells.
  Version: 1.12
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "ElementsTableViewController.h"

#import "AtomicElement.h"
#import "AtomicElementTableViewCell.h"
#import "AtomicElementViewController.h"
#import "TheElementsAppDelegate.h"
#import "ElementsDataSourceProtocol.h"


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

- (void)viewWillAppear:(BOOL)animated {
    
	// force the tableview to load
	[self.tableView reloadData];
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
