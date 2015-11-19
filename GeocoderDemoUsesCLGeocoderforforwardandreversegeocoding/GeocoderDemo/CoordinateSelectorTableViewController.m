/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UITableViewController that allows for the selection of a CLCoordinate2D.
 */

#import "CoordinateSelectorTableViewController.h"

// pull this in so we can use CNMutablePostalAddress
@import Contacts;

@interface CoordinateSelectorTableViewController ()

@property (nonatomic, strong) NSArray *searchPlacemarksCache;

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) NSIndexPath *checkedIndexPath;

@property (nonatomic, weak) IBOutlet UITableViewCell *searchCell;
@property (nonatomic, weak) IBOutlet UITextField *searchTextField;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *searchSpinner;

@property (nonatomic, weak) IBOutlet UITableViewCell *currentLocationCell;
@property (nonatomic, weak) IBOutlet UILabel *currentLocationLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *currentLocationActivityIndicatorView;

@property (readonly) NSInteger selectedIndex;

@end


#pragma mark -

@implementation CoordinateSelectorTableViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self != nil)
    {
        // do some default variables setup
        _selectedCoordinate = kCLLocationCoordinate2DInvalid;
        _selectedType = CoordinateSelectorLastSelectedTypeUndefined;
        [self updateSelectedName];
        [self updateSelectedCoordinate];
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Select a Place";
    self.clearsSelectionOnViewWillAppear = NO;
    
    // load our custom table view cells from our nib
    [[NSBundle mainBundle] loadNibNamed:@"CoordinateSelectorTableViewCells" owner:self options:nil];
    
    self.tableView.estimatedRowHeight = 44.f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self updateSelectedCoordinate];
    
    // stop updating, we don't care no more…
    if (self.selectedType == CoordinateSelectorLastSelectedTypeCurrent)
    {
        [self stopUpdatingCurrentLocation];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // start updating, we might care again
    if (self.selectedType == CoordinateSelectorLastSelectedTypeCurrent)
    {
        [self startUpdatingCurrentLocation];
    }    
}


#pragma mark - Utilities

- (NSString *)postalAddressFromPlacemark:(CLPlacemark *)placemark
{
    // use the Contacts framework to create a readable formatter address
    CNMutablePostalAddress *postalAddress = [[CNMutablePostalAddress alloc] init];
    postalAddress.street = placemark.thoroughfare;
    postalAddress.city = placemark.locality;
    postalAddress.state = placemark.administrativeArea;
    postalAddress.postalCode = placemark.postalCode;
    postalAddress.country = placemark.country;
    postalAddress.ISOCountryCode = placemark.ISOcountryCode;
    
    return [CNPostalAddressFormatter stringFromPostalAddress:postalAddress style:CNPostalAddressFormatterStyleMailingAddress];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // return the number of sections
    return 2;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    if (section == 1)
    {
        title = @"OR";
    }
    return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return the number of rows in the section
    if (section == 0)
    {
        return 1 + self.searchPlacemarksCache.count;
    }
    else
    {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
        
    // configure the cell...
    NSInteger section = indexPath.section;
    if (section == 1)
    { 
        // Current location
        //
        // load the custom cell from the Nib
        cell = _currentLocationCell;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || 
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
        {
            _currentLocationLabel.text = @"Location Services Disabled";
        }

    }
    else if ((section) == 0)
    {
        // Search
        if (indexPath.row == 0)
        {
            return _searchCell;
        }
        
        // otherwise display the list of results
        CLPlacemark *placemark = self.searchPlacemarksCache[indexPath.row - 1];
        
        (cell.textLabel).lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont systemFontOfSize:16.0];
        cell.textLabel.text = [self postalAddressFromPlacemark:placemark];
        
        (cell.detailTextLabel).lineBreakMode = NSLineBreakByWordWrapping;
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:16.0];
        CLLocationDegrees latitude = placemark.location.coordinate.latitude;
        CLLocationDegrees longitude = placemark.location.coordinate.longitude;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", latitude, longitude];
    }
    
    // show a check next to the selected option / cell
    if ([self.checkedIndexPath isEqual:indexPath])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    // set the selected type
    NSInteger section = indexPath.section;
    
    if (section == 1)
    {
        _selectedType = CoordinateSelectorLastSelectedTypeCurrent;   
    }
    else if (section == 0)
    {
        _selectedType = CoordinateSelectorLastSelectedTypeSearch;   
    }
    
    // deselect the cell
    [self.tableView cellForRowAtIndexPath:indexPath].selected = NO;

    // if this is the search cell itself do nothing
    if (_selectedType == CoordinateSelectorLastSelectedTypeSearch && indexPath.row == 0)
    {
        return;
    }

    // if location services are restricted do nothing
    if (_selectedType == CoordinateSelectorLastSelectedTypeCurrent)
    {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || 
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
        {
            return;
        }
    }
    
    // set the selected row index
    _selectedIndex = indexPath.row;
        
    // move the checkmark from the previous to the new cell
    [self.tableView cellForRowAtIndexPath:self.checkedIndexPath].accessoryType = UITableViewCellAccessoryNone;
    [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;

    // set this row to be checked on next reload
    if (self.checkedIndexPath != indexPath)
    {
        _checkedIndexPath = indexPath;
    }
        
    // set the selected name based on the selected type
    [self updateSelectedName]; 
    
    // set the selected coordinates based on the selected type and index
    [self updateSelectedCoordinate];
    
    // if current location has been selected, start updating current location
    if (_selectedType == CoordinateSelectorLastSelectedTypeCurrent)
    {
        [self startUpdatingCurrentLocation];
    }
    
    // if regular or search, pop back to previous level
    if (_selectedType == CoordinateSelectorLastSelectedTypeSearch)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark - update selected cell

// keys off selectedType and selectedCoordinates
- (void)updateSelectedName
{
    switch (_selectedType)
    {
        case CoordinateSelectorLastSelectedTypeCurrent:
        {
            _selectedName = @"Current Location";
            break;
        }
            
        case CoordinateSelectorLastSelectedTypeSearch:
        {
            CLPlacemark *placemark = self.searchPlacemarksCache[_selectedIndex - 1]; // take into account the first 'search' cell
            _selectedName = [self postalAddressFromPlacemark:placemark];
            break;
        }
            
        case CoordinateSelectorLastSelectedTypeUndefined:
        {
            _selectedName = @"Select a Place";
            break;
        }
    }
}

// keys off selectedType and selectedCoordinates 
- (void)updateSelectedCoordinate
{
    switch (_selectedType)
    {
        case CoordinateSelectorLastSelectedTypeSearch:
        { 
            // allow for the selection of search results,
            // take into account the first 'search' cell
            CLPlacemark *placemark = self.searchPlacemarksCache[_selectedIndex - 1];
            _selectedCoordinate = placemark.location.coordinate;
            break;
        }
            
        case CoordinateSelectorLastSelectedTypeUndefined:
            _selectedCoordinate = kCLLocationCoordinate2DInvalid;
            break;
            
        case CoordinateSelectorLastSelectedTypeCurrent:
            break; // no need to update for current location (CL delegate callback sets it)
    }
}


#pragma mark - current location

- (void)startUpdatingCurrentLocation
{
    // if location services are restricted do nothing
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || 
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
    {
        return;
    }

    // if locationManager does not currently exist, create it.
    if (self.locationManager == nil)
    {
        _locationManager = [[CLLocationManager alloc] init];
        (self.locationManager).delegate = self;
        self.locationManager.distanceFilter = 10.0f; //we don't need to be any more accurate than 10m
    }
    
    // for iOS 8 and later, specific user level permission is required,
    // "when-in-use" authorization grants access to the user's location
    //
    // important: be sure to include NSLocationWhenInUseUsageDescription along with its
    // explanation string in your Info.plist or startUpdatingLocation will not work.
    //
    [self.locationManager requestWhenInUseAuthorization];
    
    [self.locationManager startUpdatingLocation];
    [self.currentLocationActivityIndicatorView startAnimating];
}

- (void)stopUpdatingCurrentLocation
{
    [self.locationManager stopUpdatingLocation];
    [self.currentLocationActivityIndicatorView stopAnimating];
}


#pragma mark - CLLocationManagerDelegate - Location updates

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{		
    // if the location is older than 30s ignore
    if (fabs([newLocation.timestamp timeIntervalSinceDate:[NSDate date]]) > 30 )
    {
        return;
    }
    
    _selectedCoordinate = newLocation.coordinate;
    
    // update the current location cells detail label with these coords
    _currentLocationLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", _selectedCoordinate.latitude, _selectedCoordinate.longitude];
    
    // after recieving a location, stop updating
    [self stopUpdatingCurrentLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
    
    // stop updating
    [self stopUpdatingCurrentLocation];
    
    // set selected location to invalid location
    _selectedType = CoordinateSelectorLastSelectedTypeUndefined;
    _selectedCoordinate = kCLLocationCoordinate2DInvalid;
    _selectedName = @"Select a Location";
    _currentLocationLabel.text = @"Error updating location";
    
    // remove the check from the current Location cell
    _currentLocationCell.accessoryType = UITableViewCellAccessoryNone;
    
    // show an alert
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

// invoked when the authorization status changes for this application
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{ }


#pragma mark - placemarks search

- (void)lockSearch:(BOOL)lock
{
    self.searchTextField.enabled = !lock;
    self.searchSpinner.hidden = !lock;
}

- (void)performPlacemarksSearch
{
    [self lockSearch:YES];
    
    // perform geocode
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder geocodeAddressString:self.searchTextField.text completionHandler:^(NSArray *placemarks, NSError *error) {
        // There is no guarantee that the CLGeocodeCompletionHandler will be invoked on the main thread.
        // So we use a dispatch_async(dispatch_get_main_queue(),^{}) call to ensure that UI updates are always
        // performed from the main thread.
        //
        dispatch_async(dispatch_get_main_queue(),^ {
            if (self.checkedIndexPath.section == 0)
            {
                // clear any current selections if they are search result selections
                _checkedIndexPath = nil;
            }
            
            _searchPlacemarksCache = placemarks; // might be nil
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
            [self lockSearch:NO];
            
            if (placemarks.count == 0)
            {
                // show an alert if no results were found
                UIAlertController *alertController =
                [UIAlertController alertControllerWithTitle:@"No places were found"
                                                    message:nil
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
        });
    }];
}


#pragma mark - UITextFieldDelegate

// dismiss the keyboard for the textfields 
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.searchTextField resignFirstResponder];
   
    // initiate a search
    [self performPlacemarksSearch];
    
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self updateSelectedCoordinate];
}

@end
