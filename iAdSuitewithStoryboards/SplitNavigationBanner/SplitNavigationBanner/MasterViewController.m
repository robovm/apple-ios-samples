/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A simple view controller that manages a table view.
*/

#import "MasterViewController.h"
#import "TextViewController.h"


@interface MasterViewController () {
    NSDictionary *_data;
    NSArray *_keys;
}
@property (nonatomic, strong) TextViewController *detailViewController;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Meals";
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // on iPad only, don't clear the selection (we are displaying in a split view on iPad)
        self.clearsSelectionOnViewWillAppear = NO;
    }
    
    // remember our detail view controller
    self.detailViewController = (TextViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    // load our plist data for backing the table view
    _data = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"ipsums" withExtension:@"plist"]];
    _keys = [[_data allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // default by selecting the first row
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        
        // configure our detail view controller
        [self configureDetailItemForRow:0 viewController:self.detailViewController];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    // configure the cell
    cell.textLabel.text = _keys[indexPath.row];
 
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        // disclosure indicators on iPhone only
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)configureDetailItemForRow:(NSUInteger)row viewController:(TextViewController *)viewController {
    NSString *item = _keys[row];
    NSString *text = _data[item];
    
    viewController.text = text;
    viewController.title = item;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
        // on iPad we need to just configure our detail view when a row is selected
        [self configureDetailItemForRow:indexPath.row viewController:self.detailViewController];
    }
}


#pragma mark - Seques

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        // for iPhone, our segue will push the TextViewController, so configure it here in preparation for that push
        TextViewController *destinationVC = (TextViewController *)segue.destinationViewController;
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        [self configureDetailItemForRow:selectedIndexPath.row viewController:destinationVC];
    }
}

@end
