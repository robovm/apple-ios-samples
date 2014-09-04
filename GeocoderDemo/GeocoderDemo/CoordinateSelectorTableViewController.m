/*
     File: CoordinateSelectorTableViewController.m 
 Abstract: UITableViewController that allows for the selection of a CLCoordinate2D. 
  Version: 1.3 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2013 Apple Inc. All Rights Reserved. 
  
 */

#import "CoordinateSelectorTableViewController.h"

// pull this in so we can use ABCreateStringWithAddressDictionary()
#import <AddressBookUI/AddressBookUI.h>


#pragma mark -

@interface CoordinateSelectorTableViewController ()

@property (nonatomic, strong) NSArray *searchPlacemarksCache;

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) NSIndexPath *checkedIndexPath;

@property (nonatomic, strong) IBOutlet UITableViewCell *searchCell;
@property (nonatomic, strong) IBOutlet UITextField *searchTextField;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *searchSpinner;

@property (nonatomic, strong) IBOutlet UITableViewCell *currentLocationCell;
@property (nonatomic, strong) IBOutlet UILabel *currentLocationLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *currentLocationActivityIndicatorView;

@property (readonly) NSInteger selectedIndex;

@end


#pragma mark -

@implementation CoordinateSelectorTableViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        // do some default variables setup
        _selectedCoordinate = kCLLocationCoordinate2DInvalid;
        _selectedType = CoordinateSelectorLastSelectedTypeUndefined;
        [self updateSelectedName];
        [self updateSelectedCoordinate];
    }
    return self;
}



#pragma mark - Setup

- (void)loadNibCells
{
    // load our custom table view cells from our nib
    [[NSBundle mainBundle] loadNibNamed:@"CoordinateSelectorTableViewCells" 
                                  owner:self 
                                options:nil];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Select a Place";
    self.clearsSelectionOnViewWillAppear = NO;
    [self loadNibCells];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self updateSelectedCoordinate];
    
    // stop updating, we don't care no more…
    if (_selectedType == CoordinateSelectorLastSelectedTypeCurrent)
    {
        [self stopUpdatingCurrentLocation];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // start updating, we might care again
    if (_selectedType == CoordinateSelectorLastSelectedTypeCurrent)
    {
        [self startUpdatingCurrentLocation];
    }    
}

// rotation support for iOS 5.x and earlier, note for iOS 6.0 and later all you need is
// "UISupportedInterfaceOrientations" defined in your Info.plist
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
    else
    {
        return YES;
    }
}
#endif


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
    {
        return 1 + [_searchPlacemarksCache count];
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
        //cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || 
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
        {
            _currentLocationLabel.text = @"Location Services Disabled";
            //cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

    }
    else if ((section) == 0)
    {
        // Search
        //
        if (indexPath.row == 0)
        {
            return _searchCell;
        }
        // otherwise display the list of results
        CLPlacemark *placemark = _searchPlacemarksCache[indexPath.row - 1];
        
        NSString *addressStr = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
        cell.textLabel.text = addressStr;
        
        CLLocationDegrees latitude = placemark.location.coordinate.latitude;
        CLLocationDegrees longitude = placemark.location.coordinate.longitude;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", latitude, longitude];
    }
    
    // show a check next to the selected option / cell
    if ([_checkedIndexPath isEqual:indexPath])
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
    else if ((section) == 0)
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
    [self.tableView cellForRowAtIndexPath:_checkedIndexPath].accessoryType = UITableViewCellAccessoryNone;   
    [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;

    // set this row to be checked on next reload
    if (_checkedIndexPath != indexPath)
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
            CLPlacemark *placemark = _searchPlacemarksCache[_selectedIndex - 1]; // take into account the first 'search' cell
            _selectedName = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
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
            CLPlacemark *placemark = _searchPlacemarksCache[_selectedIndex - 1];
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
    if (!_locationManager)
    {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
        _locationManager.distanceFilter = 10.0f; //we don't need to be any more accurate than 10m
        _locationManager.purpose = @"This may be used to obtain your current location coordinates.";
    }
    
    [_locationManager startUpdatingLocation];
    [_currentLocationActivityIndicatorView startAnimating];
}

- (void)stopUpdatingCurrentLocation
{
    [_locationManager stopUpdatingLocation];
    [_currentLocationActivityIndicatorView stopAnimating];
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
    
    _selectedCoordinate = [newLocation coordinate];
    
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
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = @"Error updating location";
    alert.message = [error localizedDescription];
    [alert addButtonWithTitle:@"OK"];
    [alert show];
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
            if (_checkedIndexPath.section == 0)
            {
                // clear any current selections if they are search result selections
                _checkedIndexPath = nil;
            }
            
            _searchPlacemarksCache = placemarks; // might be nil
            [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
            [self lockSearch:NO];
            
            if (placemarks.count == 0)
            {
                // show an alert if no results were found
                UIAlertView *alert = [[UIAlertView alloc] init];
                alert.title = @"No places were found.";
                [alert addButtonWithTitle:@"OK"];
                [alert show];
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
