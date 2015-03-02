/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "DistanceViewController.h"

#import "CoordinateSelectorTableViewController.h"
#import "PlacemarksListViewController.h"


@interface DistanceViewController () <UITableViewDelegate, UITableViewDataSource>

@property (readonly) CoordinateSelectorTableViewController *toCoordinateSelector;  
@property (readonly) CoordinateSelectorTableViewController *fromCoordinateSelector;  

@end


#pragma mark -

@implementation DistanceViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _toCoordinateSelector = [[CoordinateSelectorTableViewController alloc] init];
    _fromCoordinateSelector = [[CoordinateSelectorTableViewController alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}


#pragma mark - Distance Calculation

- (double)distanceBetweenCoordinates
{
    CLLocationDegrees latitude, longitude;
    
    latitude = self.toCoordinateSelector.selectedCoordinate.latitude;
    longitude = self.toCoordinateSelector.selectedCoordinate.longitude;
    CLLocation *to = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    
    latitude = self.fromCoordinateSelector.selectedCoordinate.latitude;
    longitude = self.fromCoordinateSelector.selectedCoordinate.longitude;
    CLLocation *from = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    
    CLLocationDistance distance = [to distanceFromLocation:from];
    
    return distance;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // return the number of sections
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return the number of rows in the section
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    // to and from cells
    if (indexPath.section == 0 || indexPath.section == 1)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"selectorCell"];
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"selectorCell"];
        
        CoordinateSelectorTableViewController *selector;
        switch (indexPath.section)
        {
            default:
            case 0:
                selector = self.toCoordinateSelector;
                break;
            case 1:
                selector = self.fromCoordinateSelector;
                break;
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if (selector.selectedType != CoordinateSelectorLastSelectedTypeUndefined)
        {
            cell.textLabel.text = selector.selectedName;
            if (CLLocationCoordinate2DIsValid(selector.selectedCoordinate))
            {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", selector.selectedCoordinate.latitude, selector.selectedCoordinate.longitude];
            }
        }
        else
        {
            cell.textLabel.text = @"Select a Place";
            cell.detailTextLabel.text = @"";
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 1)
    {
        if (self.toCoordinateSelector.selectedType != CoordinateSelectorLastSelectedTypeUndefined &&
            self.fromCoordinateSelector.selectedType != CoordinateSelectorLastSelectedTypeUndefined)
        {
            return [NSString stringWithFormat:@"%.1f km\n(as the crow flies)", [self distanceBetweenCoordinates] / 1000];
        }
        else
        {
            return @"- km";
        }
    }
    return nil;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
    
    if (indexPath.section == 0)
    {
        [[self navigationController] pushViewController:self.toCoordinateSelector animated:YES];
    }
    else if (indexPath.section == 1)
    {
        [[self navigationController] pushViewController:self.fromCoordinateSelector animated:YES];
    }
}

@end
