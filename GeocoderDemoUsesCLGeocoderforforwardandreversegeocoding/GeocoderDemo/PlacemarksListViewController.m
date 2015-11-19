/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UITableViewController that Displays a list of CLPlacemarks.
 */

#import "PlacemarksListViewController.h"
#import "PlacemarkViewController.h"

static NSString *CellIdentifier = @"Cell";

@import Contacts;

@interface PlacemarksListViewController ()

@property (nonatomic, strong) NSArray *placemarks;

@end


#pragma mark -

@implementation PlacemarksListViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    return [self initWithPlacemarks:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithPlacemarks:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithPlacemarks:nil];
}

- (instancetype)initWithPlacemarks:(NSArray*)placemarks
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self != nil)
    {
        _placemarks = placemarks;
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"CLPlacemarks";
    
    self.tableView.estimatedRowHeight = 44.f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return the number of rows in the section.   
    if (self.placemarks == nil || self.placemarks.count == 0)
    {
        return 1;
    }
    
    return self.placemarks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
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

        // use the Contacts framework to create a readable formatter address
        CNMutablePostalAddress *postalAddress = [[CNMutablePostalAddress alloc] init];
        postalAddress.street = placemark.thoroughfare;
        postalAddress.city = placemark.locality;
        postalAddress.state = placemark.administrativeArea;
        postalAddress.postalCode = placemark.postalCode;
        postalAddress.country = placemark.country;
        postalAddress.ISOCountryCode = placemark.ISOcountryCode;
        
        NSString *addressString = [CNPostalAddressFormatter stringFromPostalAddress:postalAddress style:CNPostalAddressFormatterStyleMailingAddress];
  
        CLLocationDegrees latitude = placemark.location.coordinate.latitude;
        CLLocationDegrees longitude = placemark.location.coordinate.longitude;
        NSString *coordString = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", latitude, longitude];

        // strip out any empty lines in the address
        NSString *finalAttrString = @"";
        NSArray *arrSplit = [addressString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        for (NSString *subStr in arrSplit)
        {
            if (subStr.length > 0)
            {
                if (finalAttrString.length > 0)
                {
                    finalAttrString = [finalAttrString stringByAppendingString:@"\n"];
                }
                finalAttrString = [finalAttrString stringByAppendingString:subStr];
            }
        }

        (cell.textLabel).lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont systemFontOfSize:16.0];
        cell.textLabel.text = finalAttrString;
        
        (cell.detailTextLabel).lineBreakMode = NSLineBreakByWordWrapping;
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:16.0];
        cell.detailTextLabel.text = coordString;
    
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLPlacemark *placemark = self.placemarks[indexPath.row];
    PlacemarkViewController *pvc = [[PlacemarkViewController alloc] initWithPlacemark:placemark];
    [self.navigationController pushViewController:pvc animated:YES];
}

@end
