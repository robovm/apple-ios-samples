/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates using a subclass of UINavigationBar with a
  navigation controller.
 */

#import "CustomNavigationBarViewController.h"
#import "CustomNavigationBarDetailViewController.h"
#import "CustomNavigationBar.h"

@interface CustomNavigationBarViewController ()
//! An array of city names, populated from Cities.json.
@property (nonatomic, strong) NSArray *cities;
@end


@implementation CustomNavigationBarViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load some data to populate the table view with
    NSURL *citiesJSONURL = [[NSBundle mainBundle] URLForResource:@"Cities" withExtension:@"json"];
    NSData *citiesJSONData = [NSData dataWithContentsOfURL:citiesJSONURL];
    self.cities = [NSJSONSerialization JSONObjectWithData:citiesJSONData options:0 error:NULL];
    
    // Create a button and add it to our custom navigation bar.  The button
    // will return the user to the main menu when tapped.
    UIButton *returnToMenuButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [returnToMenuButton setTitle:NSLocalizedString(@"Return to Menu", @"") forState:UIControlStateNormal];
    [[returnToMenuButton titleLabel] setFont:[returnToMenuButton.titleLabel.font fontWithSize:12.f]];
    [returnToMenuButton addTarget:self action:@selector(returnToMenuAction:) forControlEvents:UIControlEventTouchUpInside];
    [(CustomNavigationBar*)self.navigationController.navigationBar setCustomButton:returnToMenuButton];
}


//| ----------------------------------------------------------------------------
//  IBAction for the button added to our custom navigation bar.
//
- (IBAction)returnToMenuAction:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}


//| ----------------------------------------------------------------------------
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"DetailSegue"])
        [(CustomNavigationBarDetailViewController*)segue.destinationViewController setCity:self.cities[self.tableView.indexPathForSelectedRow.row]];
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
