/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A simple view controller that manages a table view.
*/

#import "MasterViewController.h"
#import "TextViewController.h"


@interface MasterViewController ()

@property (nonatomic, strong) TextViewController *detailViewController;
@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, strong) NSArray *keys;

@end

@implementation MasterViewController

#pragma mark - UIViewController Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Meals";
    
    // remember our detail view controller
    self.detailViewController = (TextViewController *)((UINavigationController *)self.splitViewController.viewControllers.lastObject).topViewController;
    
    // load our plist data for backing the table view
    self.data = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"ipsums" withExtension:@"plist"]];
    self.keys = [(self.data).allKeys sortedArrayUsingSelector:@selector(compare:)];

    //  Unique config for iPads and iPhone 6 Plus
    if( self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad || self.traitCollection.displayScale == 3.0 ) {
        // don't clear the selection (we are displaying in a split view on iPad & iPhone 6 Plus)
        self.clearsSelectionOnViewWillAppear = NO;
        
        // default by selecting the first row
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        
        // configure our detail view controller
        [self configureDetailItemForRow:0 viewController:self.detailViewController];
    }
}

#pragma mark - Seques

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showDetail"]) {
        // for iPhone, our segue will push the TextViewController, so configure it here in preparation for that push
        TextViewController *destinationVC = (TextViewController *)((UINavigationController *)segue.destinationViewController).topViewController;
        NSIndexPath *selectedIndexPath = (self.tableView).indexPathForSelectedRow;
        [self configureDetailItemForRow:selectedIndexPath.row viewController:destinationVC];
    }
}

#pragma mark - Workers

- (void)configureDetailItemForRow:(NSUInteger)row viewController:(TextViewController *)viewController {
    NSString *item = self.keys[row];
    NSString *text = self.data[item];
    
    viewController.text = text;
    viewController.title = item;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (self.data).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    // configure the cell
    cell.textLabel.text = self.keys[indexPath.row];
 
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        // disclosure indicators on iPhone only
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

@end
