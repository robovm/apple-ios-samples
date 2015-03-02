/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "ForwardViewController.h"
#import "PlacemarksListViewController.h"

@interface ForwardViewController () <UITextFieldDelegate,
                                     UITableViewDelegate,
                                     UITableViewDataSource,
                                     CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager; // location manager for current location

@property (nonatomic, strong) IBOutlet UITableViewCell *searchStringCell;
@property (nonatomic, strong) IBOutlet UITextField *searchStringTextField;

@property (nonatomic, strong) IBOutlet UISwitch *searchHintSwitch;

@property (nonatomic, strong) IBOutlet UITableViewCell *searchRadiusCell;
@property (nonatomic, strong) IBOutlet UILabel *searchRadiusLabel;
@property (nonatomic, strong) IBOutlet UISlider *searchRadiusSlider;

@property (readonly) CLLocationCoordinate2D selectedCoordinate;

@property (weak, readonly) UIActivityIndicatorView *spinner;
@property (weak, readonly) UIActivityIndicatorView *currentLocationActivityIndicatorView;

@end


#pragma mark -

@implementation ForwardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    _selectedCoordinate = kCLLocationCoordinate2DInvalid;
    
    // load our custom table view cells from our nib
    [[NSBundle mainBundle] loadNibNamed:@"ForwardViewControllerCells" 
                                  owner:self 
                                options:nil];
    
#if 0
    // forward geocode request using NSDictionary -
    //
    // geocodeAddressDictionary:completionHandler: takes an address dictionary as defined by the AddressBook framework.
    // You can obtain an address dictionary from an ABPerson by retrieving the kABPersonAddressProperty property.
    // Alternately, one can be constructed using the kABPersonAddress* keys defined in <AddressBook/ABPerson.h>.
    //
    NSDictionary *locationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"San Francisco", kABPersonAddressCityKey,
                                            @"United States", kABPersonAddressCountryKey,
                                            @"us", kABPersonAddressCountryCodeKey,
                                            @"1398 Haight Street", kABPersonAddressStreetKey,
                                            @"94117", kABPersonAddressZIPKey,
                                        nil];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressDictionary:locationDictionary completionHandler:^(NSArray *placemarks, NSError *error)
    { }];
#endif
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
    if (!_currentLocationActivityIndicatorView)
    {
        // add the spinner to the table cell
        UIActivityIndicatorView *curLocSpinner =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [curLocSpinner startAnimating];    
        [curLocSpinner setFrame:CGRectMake(200.0, 0.0, 22.0, 22.0)];
        [curLocSpinner setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
        assert(cell);
        if (cell)
        {
            cell.accessoryView = curLocSpinner;
        }
        
        _currentLocationActivityIndicatorView = curLocSpinner; // keep a weak ref around for later
    }
    
    [self showSpinner:_currentLocationActivityIndicatorView withShowState:show];
}

- (void)showSpinner:(BOOL)show
{
    if (_spinner == nil)
    {
        // add the spinner to the table's footer view
        UIView *containerView = [[UIView alloc] initWithFrame:
                                    CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.frame), 22.0)];
        UIActivityIndicatorView *spinner =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
           
        // size and center the spinner
        [spinner setFrame:CGRectZero];
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
    self.searchHintSwitch.enabled = !lock;
    self.searchRadiusSlider.enabled = !lock;
    
    [self showSpinner:lock];
}


#pragma mark - Display Results

// display the results
- (void)displayPlacemarks:(NSArray *)placemarks
{
    dispatch_async(dispatch_get_main_queue(),^ {
        [self lockUI:NO];
        
        PlacemarksListViewController *plvc = [[PlacemarksListViewController alloc] initWithPlacemarks:placemarks preferCoord:YES];
        [self.navigationController pushViewController:plvc animated:YES];
    });
}

// display a given NSError in an UIAlertView
- (void)displayError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(),^ {
        [self lockUI:NO];
       
        NSString *message;
        switch ([error code])
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
           default:
               message = [error description];
               break;
        }
       
        UIAlertView *alert =  [[UIAlertView alloc] initWithTitle:@"An error occurred."
                                                        message:message
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];;
        [alert show];
    });   
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // return the number of sections
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return the number of rows in the section
    if (section == 1)
        return self.searchHintSwitch.on ? 3 : 1;
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // ----- interface builder generated cells -----
    //
    // search string cell
    if (indexPath.section == 0)
    {
        return self.searchStringCell;
    }
    
    // search radius cell
    if (indexPath.section == 1 && indexPath.row == 2)
    {
        return self.searchRadiusCell;
    } 
    
    // ----- non interface builder generated cells -----
    //
    // search hint cell
    if (indexPath.section == 1 && indexPath.row == 0)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"radiusToggleCell"];
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"radiusToggleCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _searchHintSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [self.searchHintSwitch sizeToFit];
        [self.searchHintSwitch addTarget:self action:@selector(hintSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = self.searchHintSwitch;
        
        cell.textLabel.text = @"Include Hint Region";
        return cell;
    }    

    // current location cell
    if (indexPath.section == 1 && indexPath.row == 1)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"radiusCell"];
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"radiusCell"];

        cell.textLabel.text = @"Current Location";
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || 
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted )
        {
            cell.detailTextLabel.text = @"Location Services Disabled";
        }
        else
        {
           cell.detailTextLabel.text = @"<unknown>"; 
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }    
    
    // basic cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"basicCell"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"basicCell"];
    
    // geocode button
    if (indexPath.section == 2 && indexPath.row == 0)
    {
        cell.textLabel.text = @"Geocode String";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }

    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
    
    if (indexPath.section == 2 && indexPath.row == 0)
    {
        // perform the Geocode
        [self performStringGeocode:self];
    }
}


#pragma mark - UITextFieldDelegate

// dismiss the keyboard for the textfields 
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // dismiss the keyboard upon a scroll
    [self.searchStringTextField resignFirstResponder];
}


#pragma mark - CLLocationManagerDelegate

- (void)startUpdatingCurrentLocation
{
    // if location services are restricted do nothing
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || 
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
    {
        return;
    }
    
    // if locationManager does not currently exist, create it
    if (self.locationManager == nil)
    {
        _locationManager = [[CLLocationManager alloc] init];
        [self.locationManager setDelegate:self];
        self.locationManager.distanceFilter = 10.0f; // we don't need to be any more accurate than 10m
    }
    
    // for iOS 8, specific user level permission is required,
    // "when-in-use" authorization grants access to the user's location
    //
    // important: be sure to include NSLocationWhenInUseUsageDescription along with its
    // explanation string in your Info.plist or startUpdatingLocation will not work.
    //
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
    {
        [_locationManager requestWhenInUseAuthorization];
    }
    
    [_locationManager startUpdatingLocation];
    
    [self showCurrentLocationSpinner:YES];
}

- (void)stopUpdatingCurrentLocation
{
    [_locationManager stopUpdatingLocation];
    
    [self showCurrentLocationSpinner:NO];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{		
    // if the location is older than 30s ignore
    if (fabs([newLocation.timestamp timeIntervalSinceDate:[NSDate date]]) > 30)
    {
        return;
    }
    
    _selectedCoordinate = [newLocation coordinate];
    
    // update the current location cells detail label with these coords
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", _selectedCoordinate.latitude, _selectedCoordinate.longitude];
    
    // after recieving a location, stop updating
    [self stopUpdatingCurrentLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
    
    // stop updating
    [self stopUpdatingCurrentLocation];
    
    // since we got an error, set selected location to invalid location
    _selectedCoordinate = kCLLocationCoordinate2DInvalid;

    // show the error alert
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = @"Error obtaining location";
    alert.message = [error localizedDescription];
    [alert addButtonWithTitle:@"OK"];
    [alert show];
}


#pragma mark - Actions

- (IBAction)hintSwitchChanged:(id)sender
{
    // show or hide the region hint cells
    NSArray *indexes = @[[NSIndexPath indexPathForRow:1 inSection:1], [NSIndexPath indexPathForRow:2 inSection:1]];
    
    if (self.searchHintSwitch.on)
    {
        [self.tableView insertRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
        
        // start searching for our location coordinates
        [self startUpdatingCurrentLocation];
    }
    else
    {
        [self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (IBAction)radiusChanged:(id)sender
{
    self.searchRadiusLabel.text = [NSString stringWithFormat:@"%1.1f km", self.searchRadiusSlider.value/1000.0f];
}

- (IBAction)performStringGeocode:(id)sender
{
    // dismiss the keyboard if it's currently open
    if ([self.searchStringTextField isFirstResponder])
    {
        [self.searchStringTextField resignFirstResponder];
    }
    
    [self lockUI:YES];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    // if we are going to includer region hint
    if (self.searchHintSwitch.on)
    {
        // use hint region
        CLLocationDistance dist = self.searchRadiusSlider.value; // 50,000m (50km)
        CLLocationCoordinate2D point = _selectedCoordinate;
        CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:point
                                                                     radius:dist
                                                                 identifier:@"Hint Region"];
        
        [geocoder geocodeAddressString:self.searchStringTextField.text inRegion:region completionHandler:^(NSArray *placemarks, NSError *error)
         {
             if (error){
                 NSLog(@"Geocode failed with error: %@", error);
                 [self displayError:error];
                 return;
             }
             
             NSLog(@"Received placemarks: %@", placemarks);
             [self displayPlacemarks:placemarks];
         }];
    }
    else
    {
        // don't use a hint region
        [geocoder geocodeAddressString:self.searchStringTextField.text completionHandler:^(NSArray *placemarks, NSError *error) {
             if (error)
             {
                 NSLog(@"Geocode failed with error: %@", error);
                 [self displayError:error];
                 return;
             }
             
             NSLog(@"Received placemarks: %@", placemarks);
             [self displayPlacemarks:placemarks];
         }];
    }
}

@end
