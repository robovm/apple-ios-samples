/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates using a custom back button image with no chevron and
  not text.
 */

#import "CustomBackButtonViewController.h"
#import "CustomBackButtonNavController.h"
#import "CustomBackButtonDetailViewController.h"

@interface CustomBackButtonViewController ()
//! An array of city names, populated from Cities.json.
@property (nonatomic, strong) NSArray *cities;
@end


@implementation CustomBackButtonViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load some data to populate the table view with
    NSURL *citiesJSONURL = [[NSBundle mainBundle] URLForResource:@"Cities" withExtension:@"json"];
    NSData *citiesJSONData = [NSData dataWithContentsOfURL:citiesJSONURL];
    self.cities = [NSJSONSerialization JSONObjectWithData:citiesJSONData options:0 error:NULL];
    
    // Note that images configured as the back bar button's background do
    // not have the current tintColor applied to them, they are displayed
    // as it.
    UIImage *backButtonBackgroundImage = [UIImage imageNamed:@"Menu"];
    // The background should be pinned to the left and not stretch.
    backButtonBackgroundImage = [backButtonBackgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, backButtonBackgroundImage.size.width - 1, 0, 0)];
    
    id appearance = [UIBarButtonItem appearanceWhenContainedIn:[CustomBackButtonNavController class], nil];
    [appearance setBackButtonBackgroundImage:backButtonBackgroundImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    // Provide an empty backBarButton to hide the 'Back' text present by
    // default in the back button.
    //
    // NOTE: You do not need to provide a target or action.  These are set
    //       by the navigation bar.
    // NOTE: Setting the title of this bar button item to ' ' (space) works
    //       around a bug in iOS 7.0.x where the background image would be
    //       horizontally compressed if the back button title is empty.
    UIBarButtonItem *backBarButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:NULL];
    self.navigationItem.backBarButtonItem = backBarButton;
    
    // NOTE: There is a bug in iOS 7.0.x where the background of the back bar
    //       button item will not appear until the back button has been tapped
    //       once.
}


//| ----------------------------------------------------------------------------
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"DetailSegue"])
        [(CustomBackButtonDetailViewController*)segue.destinationViewController setCity:self.cities[self.tableView.indexPathForSelectedRow.row]];
}

#pragma mark -
#pragma mark UITableViewDataSource

//| ----------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cities.count;
}


//| ----------------------------------------------------------------------------
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = self.cities[indexPath.row];
    
    return cell;
}

@end
