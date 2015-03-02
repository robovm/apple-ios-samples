/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "PlacemarkViewController.h"

#import <QuartzCore/QuartzCore.h>   // for CALayer support

@interface PlacemarkViewController ()
{
    UITableViewCell *_mapCell;
    BOOL _preferCoord;
}

@property (nonatomic, strong) CLPlacemark *placemark;

@end


#pragma mark -

@implementation PlacemarkViewController

NSInteger const PlacemarkViewControllerNumberOfSections = 5;

- (instancetype)initWithPlacemark:(CLPlacemark *)placemark preferCoord:(BOOL)shouldPreferCoord
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _placemark = placemark;
        _preferCoord = shouldPreferCoord;
    }
    return self;
}

- (instancetype)initWithPlacemark:(CLPlacemark *)placemark
{
    return [self initWithPlacemark:placemark preferCoord:NO];
}

- (instancetype)init
{
    return [self initWithPlacemark:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"CLPlacemark Details";
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return PlacemarkViewControllerNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *counts;
    if (_preferCoord)
    {
        counts = @[@1,  //map
                   @8,  //location
                   @4,  //region
                   @10, //dict
                   @1]; //map url
    }
    else
    {
        counts = @[@10, //dict
                  @4,   //region
                  @8,   //location
                  @1,   //map
                  @1];  //map url
    }
    
    return [counts[section] integerValue];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *titles;
    if (_preferCoord)
    {
        titles = @[@"",                                      // map
                   @"location - (CLLocation)",               // location
                   @"region - (CLRegion)",                   // region
                   @"addressDictionary - (NSDictionary)",    // dict
                   @""];
    }
    else
    {
        titles = @[@"addressDictionary - (NSDictionary)",    // dict
                   @"region - (CLRegion)",                   // region
                   @"location - (CLLocation)",               // location
                   @"Map",                                   // map
                   @""];
    }
    
    return titles[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    
    if (_preferCoord)
    {
        switch (section)
        {
            case 0: return [self cellForMapView];
            case 1: return [self cellForLocationIndex:indexPath.row];
            case 2: return [self cellForRegionIndex:indexPath.row];
            case 3: return [self cellForAddressDictionaryIndex:indexPath.row];
            case 4: return [self cellForMapURL];
        }
    }
    else
    {
        switch (section)
        {
            case 0: return [self cellForAddressDictionaryIndex:indexPath.row];
            case 1: return [self cellForRegionIndex:indexPath.row];
            case 2: return [self cellForLocationIndex:indexPath.row];
            case 3: return [self cellForMapView];
            case 4: return [self cellForMapURL];
        }
    }
    return nil;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger mapSection = _preferCoord ? 0 : 3;
    if (indexPath.section == mapSection)
    { 
        return 240.0f; // map height
    }
    return [self.tableView rowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // if its the map url cell, open the location in Google maps
    //
    if (indexPath.section == 4) // map url is always last section
    {    
        NSString *ll = [NSString stringWithFormat:@"%f,%f",
                            self.placemark.location.coordinate.latitude,
                            self.placemark.location.coordinate.longitude];
        ll = [ll stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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
    
    if (index >= (NSInteger)[keys count])
        index = [keys count] - 1;
    
    UITableViewCell *cell = [self blankCell];
    
    // setup
    NSString *key = keys[index];
    NSString *ivar = [self.placemark performSelector:NSSelectorFromString(key)];
    NSString *dict = [self.placemark addressDictionary][key];
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
    
    if (index >= (NSInteger)[keys count])
        index = [keys count] - 1;
    
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
        ivar = [self displayStringForDouble:[self.placemark.location coordinate].latitude];
    }
    else if ([key isEqualToString:@"coordinate.longitude"])
    {
        ivar = [self displayStringForDouble:[self.placemark.location coordinate].longitude];
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
    
    if (index >= (NSInteger)[keys count])
        index = [keys count] - 1;
    
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

- (UITableViewCell *)cellForMapView
{
    if (_mapCell)
        return _mapCell;
    
    // if not cached, setup the map view...
    CGFloat cellWidth = self.view.bounds.size.width - 20;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        cellWidth = self.view.bounds.size.width - 90;
    }
    
    CGRect frame = CGRectMake(0, 0, cellWidth, 240);
    MKMapView *map = [[MKMapView alloc] initWithFrame:frame];
    MKCoordinateRegion region =  MKCoordinateRegionMakeWithDistance(self.placemark.location.coordinate, 200, 200);
    [map setRegion:region];
    
    map.layer.masksToBounds = YES;
    map.layer.cornerRadius = 10.0;
    map.mapType = MKMapTypeStandard;
    [map setScrollEnabled:NO];
    
    // add a pin using self as the object implementing the MKAnnotation protocol
    [map addAnnotation:self];
    
    NSString * cellID = @"Cell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];    
    
    [cell.contentView addSubview:map];
    
    _mapCell = cell;
    return cell;
}

- (UITableViewCell *)cellForMapURL
{
    NSString * cellID = @"Cell";
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
