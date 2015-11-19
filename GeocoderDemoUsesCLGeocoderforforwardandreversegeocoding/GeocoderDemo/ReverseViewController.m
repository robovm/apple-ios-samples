/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 View controller in charge of reverse geocoding.
 */

#import "ReverseViewController.h"
#import "PlacemarksListViewController.h"

#define kSanFranciscoCoordinate CLLocationCoordinate2DMake(37.776278, -122.419367)

@interface ReverseViewController () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (readonly) CLLocationCoordinate2D currentUserCoordinate;
@property (readonly) NSInteger selectedRow;

@property (weak, readonly) UIActivityIndicatorView *spinner;
@property (weak, readonly) UIActivityIndicatorView *currentLocationActivityIndicatorView;

@end


#pragma mark -

@implementation ReverseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // start with San Francisco
    _currentUserCoordinate = kCLLocationCoordinate2DInvalid;
    _selectedRow = 0;
}


#pragma mark - UI Handling

- (void)showSpinner:(UIActivityIndicatorView *)whichSpinner withShowState:(BOOL)show
{
    whichSpinner.hidden = (show) ? NO : YES;
    if (show)
    {
        [whichSpinner startAnimating];
    }
    else
    {
        [whichSpinner stopAnimating];
    }
}

- (void)showCurrentLocationSpinner:(BOOL)show
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assert(cell);
    
    if (!self.currentLocationActivityIndicatorView)
    {
        // add the spinner to the table cell
        UIActivityIndicatorView *curLocSpinner =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [curLocSpinner startAnimating];    
        curLocSpinner.frame = CGRectMake(200.0, 0.0, 22.0, 22.0);
        curLocSpinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        _currentLocationActivityIndicatorView = curLocSpinner; // keep a weak ref around for later
        cell.accessoryView = _currentLocationActivityIndicatorView;
    }
    
    if (!show && _selectedRow == 1)
    {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

- (void)showSpinner:(BOOL)show
{
    if (self.spinner == nil)
    {
        // add the spinner to the table's footer view
        UIView *containerView = [[UIView alloc] initWithFrame:
                                    CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.frame), 22.0)];
        UIActivityIndicatorView *spinner =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
           
        // size and center the spinner
        spinner.frame = CGRectZero;
        [spinner sizeToFit];
        CGRect frame = spinner.frame;
        frame.origin.x = (CGRectGetWidth(self.tableView.frame) - CGRectGetWidth(frame)) / 2.0;
        spinner.frame = frame;
        [spinner startAnimating]; 
        
        [containerView addSubview:spinner];
        self.tableView.tableFooterView = containerView;
        _spinner = spinner; // keep a weak ref around for later
    }
    
    [self showSpinner:self.spinner withShowState:show];
}

- (void)lockUI:(BOOL)lock
{
    // prevent user interaction while we are processing the forward geocoding
    self.tableView.allowsSelection = !lock;
    [self showSpinner:lock];
}


#pragma mark - Display Results

// display the results
- (void)displayPlacemarks:(NSArray *)placemarks
{
    dispatch_async(dispatch_get_main_queue(),^ {
        [self lockUI:NO];
        
        PlacemarksListViewController *plvc = [[PlacemarksListViewController alloc] initWithPlacemarks:placemarks];
        [self.navigationController pushViewController:plvc animated:YES];
    });
}

// display a given NSError in an UIAlertView
- (void)displayError:(NSError*)error
{
    dispatch_async(dispatch_get_main_queue(),^ {
        [self lockUI:NO];

        NSString *message;
        switch (error.code)
        {
            case kCLErrorGeocodeFoundNoResult:
                message = @"kCLErrorGeocodeFoundNoResult";
                break;
            case kCLErrorGeocodeCanceled:
                message = @"kCLErrorGeocodeCanceled";
                break;
            case kCLErrorGeocodeFoundPartialResult:
                message = @"kCLErrorGeocodeFoundNoResult";
                break;
            default: message = error.description;
                break;
        }

        UIAlertController *alertController =
            [UIAlertController alertControllerWithTitle:@"An error occurred."
                                                message:message
                                         preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok =
        [UIAlertAction actionWithTitle:@"OK"style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   // do some thing here
                               }];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
    });   
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
    if (section == 0)
        return 2;
    else
        return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return @"Choose a location:";
    else
        return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"basicCell"];
    if (!cell)
    {
        UITableViewCellStyle style = (indexPath.section == 0) ? UITableViewCellStyleSubtitle : UITableViewCellStyleDefault; 
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:@"basicCell"];
    }
       
    if (indexPath.section == 0)
    {
        switch (indexPath.row)
        {
            case 0:
            {    
                cell.textLabel.text = @"San Francisco";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", kSanFranciscoCoordinate.latitude, kSanFranciscoCoordinate.longitude];
                break;
            }
                
            case 1:
            {
                cell.textLabel.text = @"Current Location";
                if (CLLocationCoordinate2DIsValid(_currentUserCoordinate))
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", _currentUserCoordinate.latitude, _currentUserCoordinate.longitude];
                else
                {
                    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || 
                        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted )
                    {
                        cell.detailTextLabel.text = @"Location Services Disabled";
                    }
                    else
                    {
                        cell.detailTextLabel.text = @"<unknown>"; 
                    }
                }
                break;
            }
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UITableViewCellAccessoryType accessoryType =
            (_selectedRow == indexPath.row) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        cell.accessoryType = accessoryType;
    }
    else
    {
        cell.textLabel.text = @"Geocode Coordinate";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }    
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
    
    if (indexPath.section == 1 && indexPath.row == 0)
    {
        // perform the Geocode
        [self performCoordinateGeocode:self];
    }
    else
    {
        NSInteger whichCellRow = (indexPath.row == 0) ? 1 : 0;
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:whichCellRow inSection:0]];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        if (indexPath.row == 1)
        {
            [self startUpdatingCurrentLocation];
        }
        
        _selectedRow = indexPath.row;
    }
}


#pragma mark - CLLocationManagerDelegate

- (void)startUpdatingCurrentLocation
{
    // if location services are restricted do nothing
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || 
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted )
    {
        return;
    }
    
    // if locationManager does not currently exist, create it
    if (self.locationManager == nil)
    {
        _locationManager = [[CLLocationManager alloc] init];
        (self.locationManager).delegate = self;
        self.locationManager.distanceFilter = 10.0f; // we don't need to be any more accurate than 10m
    }
    
    // for iOS 8 and later, specific user level permission is required,
    // "when-in-use" authorization grants access to the user's location
    //
    // important: be sure to include NSLocationWhenInUseUsageDescription along with its
    // explanation string in your Info.plist or startUpdatingLocation will not work.
    //
    [self.locationManager requestWhenInUseAuthorization];
    
    [self.locationManager startUpdatingLocation];
    
    [self showCurrentLocationSpinner:YES];
}

- (void)stopUpdatingCurrentLocation
{
    [self.locationManager stopUpdatingLocation];
    
    [self showCurrentLocationSpinner:NO];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{		
    // if the location is older than 30s ignore
    if (fabs([newLocation.timestamp timeIntervalSinceDate:[NSDate date]]) > 30)
    {
        return;
    }
    
    _currentUserCoordinate = newLocation.coordinate;
    _selectedRow = 1;
    
    // update the current location cells detail label with these coords
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", _currentUserCoordinate.latitude, _currentUserCoordinate.longitude];

    // after recieving a location, stop updating
    [self stopUpdatingCurrentLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
    
    // stop updating
    [self stopUpdatingCurrentLocation];
    
    // since we got an error, set selected location to invalid location
    _currentUserCoordinate = kCLLocationCoordinate2DInvalid;

    // show the error alert
    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:@"Error updating location"
                                            message:error.localizedDescription
                                     preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok =
        [UIAlertAction actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                               // do some thing here
                           }];
    [alertController addAction:ok];
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Actions

- (IBAction)performCoordinateGeocode:(id)sender
{
    [self lockUI:YES];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    CLLocationCoordinate2D coord = (_selectedRow == 0) ? kSanFranciscoCoordinate : _currentUserCoordinate;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error){
            NSLog(@"Geocode failed with error: %@", error);
            [self displayError:error];
            return;
        }
        
        //NSLog(@"Received placemarks: %@", placemarks);
        [self displayPlacemarks:placemarks];
    }];
}

@end
