/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UITableViewController that displays the propeties of a CLPlacemark.
 */

#import "PlacemarkViewController.h"

// custom table view cell for holding the placemark's map
@interface MapTableViewCell : UITableViewCell
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@end
@implementation MapTableViewCell
@end


#pragma mark -

@interface PlacemarkViewController ()

@property (nonatomic, strong) CLPlacemark *placemark;
@property (nonatomic, strong) IBOutlet MapTableViewCell *mapCell;   // points to a custom cell in "MapCell.xib"

@end


#pragma mark -

@implementation PlacemarkViewController

@dynamic title;
@dynamic description;

NSInteger const PlacemarkViewControllerNumberOfSections = 5;

- (instancetype)initWithPlacemark:(CLPlacemark *)placemark
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self != nil)
    {
        _placemark = placemark;
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    return [self initWithPlacemark:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithPlacemark:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithPlacemark:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"CLPlacemark Details";
    
    // load our custom map cell from 'MapCell.xib' (connects our IBOutlet to that cell)
    [[NSBundle mainBundle] loadNibNamed:@"MapCell" owner:self options:nil];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return PlacemarkViewControllerNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *counts;

    counts = @[@10, //dict
              @4,   //region
              @8,   //location
              @1,   //map
              @1];  //map url

    return [counts[section] integerValue];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *titles = @[@"addressDictionary - (NSDictionary)",    // dict
                        @"region - (CLRegion)",                   // region
                        @"location - (CLLocation)",               // location
                        @"Map",                                   // map
                        @""];
    return titles[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0: return [self cellForAddressDictionaryIndex:indexPath.row];
        case 1: return [self cellForRegionIndex:indexPath.row];
        case 2: return [self cellForLocationIndex:indexPath.row];
        case 3:
        {
            // point the map to our placemark
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.placemark.location.coordinate, 200, 200);
            self.mapCell.mapView.region = region;
            
            // add a pin using self as the object implementing the MKAnnotation protocol
            [self.mapCell.mapView addAnnotation:self];
            
            return self.mapCell;
        }
        case 4: return [self cellForMapURL];
    }

    return nil;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger mapSection = 3;
    if (indexPath.section == mapSection)
    { 
        return 240.0f; // map cell height
    }
    return self.tableView.rowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // if it's the map url cell, open the location in Google maps
    //
    if (indexPath.section == 4) // map url is always last section
    {    
        NSString *ll = [NSString stringWithFormat:@"%f,%f",
                            self.placemark.location.coordinate.latitude,
                            self.placemark.location.coordinate.longitude];
        ll = [ll stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
        NSString *url = [NSString stringWithFormat:@"http://maps.apple.com/?q=%@", ll];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];

        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}


#pragma mark - Cell Generators

- (UITableViewCell *)blankCell
{
    NSString *cellID = @"Cell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UITableViewCell *)cellForAddressDictionaryIndex:(NSInteger)index
{
    NSArray const *keys = @[@"name",
                            @"thoroughfare",
                            @"subThoroughfare",
                            @"locality",
                            @"subLocality",
                            @"administrativeArea",
                            @"subAdministrativeArea",
                            @"postalCode",
                            @"ISOcountryCode",
                            @"country"];
    
    if (index >= (NSInteger)keys.count)
    {
        index = keys.count - 1;
    }
    
    UITableViewCell *cell = [self blankCell];
    
    // setup
    NSString *key = keys[index];
    NSString *ivar = [self.placemark performSelector:NSSelectorFromString(key)];
    NSString *dict = (self.placemark).addressDictionary[key];
    if (dict)
    {
        // assert that ivar and dict values are the same
        NSAssert(![ivar isEqualToString:dict], @"value from ivar accessor and from addressDictionary should always be the same! %@ != %@", ivar, dict);
    }
    
    // set cell attributes
    cell.textLabel.text = key;
    cell.detailTextLabel.text = ivar;
    
    return cell;
}

- (UITableViewCell *)cellForLocationIndex:(NSInteger)index
{
    NSArray const *keys = @[@"coordinate.latitude",
                            @"coordinate.longitude",
                            @"altitude",
                            @"horizontalAccuracy",
                            @"verticalAccuracy",
                            @"course",
                            @"speed",
                            @"timestamp"];
    
    if (index >= (NSInteger)keys.count)
    {
        index = keys.count - 1;
    }
    
    UITableViewCell *cell = [self blankCell];
    
    // setup
    NSString *key = keys[index];
    NSString *ivar = @"";
    
    // look up the values, special case lat and long and timestamp but first, special case placemark being nil.
    if (self.placemark.location == nil)
    {
        ivar = @"location is nil.";
    }
    else if ([key isEqualToString:@"coordinate.latitude"])
    {
        ivar = [self displayStringForDouble:(self.placemark.location).coordinate.latitude];
    }
    else if ([key isEqualToString:@"coordinate.longitude"])
    {
        ivar = [self displayStringForDouble:(self.placemark.location).coordinate.longitude];
    }
    else if ([key isEqualToString:@"timestamp"])
    {
        ivar = [NSString stringWithFormat:@"%@", [self.placemark.location performSelector:NSSelectorFromString(key)]];
    }
    else
    {
        double var = [self doubleForObject:self.placemark.location andSelector:NSSelectorFromString(key)];
        ivar = [self displayStringForDouble:var];
    }
    
    // set cell attributes
    cell.textLabel.text = key;
    cell.detailTextLabel.text = ivar;
    
    return cell;
}

- (UITableViewCell *)cellForRegionIndex:(NSInteger)index
{
    NSArray const *keys = @[@"center.latitude",
                            @"center.longitude",
                            @"radius",
                            @"identifier"];
    
    if (index >= (NSInteger)keys.count)
    {
        index = keys.count - 1;
    }
    
    UITableViewCell *cell = [self blankCell];
    
    // setup
    NSString *key = keys[index];
    NSString *ivar;
    
    // look up the values, special case lat and long and timestamp but first special case region being nil
    if (self.placemark.region == nil)
    {
        ivar = @"region is nil.";
    }
    else if ([key isEqualToString:@"center.latitude"])
    {
        ivar = [self displayStringForDouble:self.placemark.location.coordinate.latitude];
    }
    else if ([key isEqualToString:@"center.longitude"])
    {
        ivar = [self displayStringForDouble:self.placemark.location.coordinate.longitude];
    }
    else if ([key isEqualToString:@"identifier"])
    {
        ivar = [NSString stringWithFormat:@"%@", [self.placemark.region performSelector:NSSelectorFromString(key)]];
    }
    else
    {
        double var = [self doubleForObject:self.placemark.region andSelector:NSSelectorFromString(key)];
        ivar = [self displayStringForDouble:var];
    }
    
    // set cell attributes
    cell.textLabel.text = key;
    cell.detailTextLabel.text = ivar;
    
    return cell;    
}

- (UITableViewCell *)cellForMapURL
{
    NSString *cellID = @"Cell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];   
    
    cell.textLabel.text = @"View in Maps";
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    return cell;
}


#pragma mark - Display Utilities

// performSelector is only for objects
- (double)doubleForObject:(id)object andSelector:(SEL)selector
{
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[object methodSignatureForSelector:selector]];
    
    [inv invoke];
    double result;
    [inv getReturnValue:&result];
    
    return result;
}

// don't try and print any NaNs. these throw exceptions in strings
- (NSString *)displayStringForDouble:(double)aDouble
{
    if (isnan(aDouble))
    {
        return @"N/A";
    }
    else
    {
        return [NSString stringWithFormat:@"%f", aDouble];
    }
}


#pragma mark - MKAnnotation Protocol (for map pin)

- (CLLocationCoordinate2D)coordinate
{
    return self.placemark.location.coordinate;
}

- (NSString *)title
{
    return self.placemark.thoroughfare;
}

@end
