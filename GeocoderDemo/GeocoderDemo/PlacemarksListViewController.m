/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "PlacemarksListViewController.h"
#import "PlacemarkViewController.h"

#import <AddressBookUI/AddressBookUI.h>

@interface PlacemarksListViewController ()
{
    NSArray *_placemarks;
    BOOL _preferCoord;
}

@property (nonatomic, strong) NSArray *placemarks;
@end


#pragma mark -

@implementation PlacemarksListViewController

// show the coord in the main textField in the cell if YES
- (instancetype)initWithPlacemarks:(NSArray*)placemarks preferCoord:(BOOL)shouldPreferCoord
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        _placemarks = placemarks;
        _preferCoord = shouldPreferCoord;
    }
    return self;

}

- (instancetype)initWithPlacemarks:(NSArray*)placemarks
{
    return [self initWithPlacemarks:placemarks preferCoord:NO];
}

- (instancetype)init
{
    return [self initWithPlacemarks:nil];
}



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"CLPlacemarks";
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return the number of rows in the section.   
    if (self.placemarks == nil || self.placemarks.count == 0)
        return 1;
    
    return self.placemarks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if (self.placemarks == nil || self.placemarks.count == 0)
    {
        // show a zero results cell
        cell.textLabel.text = @"No Placemarks..";
    }
    else
    {
        CLPlacemark *placemark = self.placemarks[indexPath.row];
        
        // use the AddressBook framework to create an address dictionary
        NSString *addressString = CFBridgingRelease(CFBridgingRetain(ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO)));
        
        CLLocationDegrees latitude = placemark.location.coordinate.latitude;
        CLLocationDegrees longitude = placemark.location.coordinate.longitude;
        NSString *coordString = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", latitude, longitude];
        // switch around our strings depending on our priority at init time
        cell.textLabel.text = _preferCoord ? coordString : addressString;
        cell.detailTextLabel.text = _preferCoord ? addressString : coordString;

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLPlacemark *placemark = self.placemarks[indexPath.row];
    PlacemarkViewController *pvc = [[PlacemarkViewController alloc] initWithPlacemark:placemark preferCoord:_preferCoord];
    [self.navigationController pushViewController:pvc animated:YES];
}

@end
