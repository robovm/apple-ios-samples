/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 View controller for displaying the earthquake list.
 */

#import "APLViewController.h"
#import "APLEarthQuakeSource.h"

#import "APLEarthquake.h"
#import "APLEarthquakeTableViewCell.h"

@import MapKit;   // for CLLocationCoordinate2D and MKPlacemark


@interface APLViewController ()

@property (nonatomic, strong) APLEarthQuakeSource *earthQuakeSource;

@property (assign) id localChangedObserver;

@property (nonatomic, strong) UIAlertController *alert;

@end


#pragma mark -

@implementation APLViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    _earthQuakeSource = [[APLEarthQuakeSource alloc] init];
    
    // listen for incoming earthquakes from our data source using KVO
    [self.earthQuakeSource addObserver:self forKeyPath:@"earthquakes" options:0 context:nil];
    
    // listen for errors reported by our data source using KVO, so we can report it in our own way
    [self.earthQuakeSource addObserver:self forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:nil];
    
    // Our NSNotification callback when the user changes the locale (region format) in Settings, so we are notified here to
    // update the date format in the table view cells
    //
    _localChangedObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:NSCurrentLocaleDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *notification) {
            [self.tableView reloadData];
        }];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.earthQuakeSource startEarthQuakeLookup];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.localChangedObserver];
}


#pragma mark - UITableViewDelegate

/**
 * The number of rows is equal to the number of earthquakes in the array.
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.earthQuakeSource.earthquakes.count;
}

/**
 * Return the proper table view cell for each earthquake
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *kEarthquakeCellID = @"EarthquakeCellID";
  	APLEarthquakeTableViewCell *cell = (APLEarthquakeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kEarthquakeCellID];

    // Get the specific earthquake for this row.
    APLEarthquake *earthquake = self.earthQuakeSource.earthquakes[indexPath.row];
    
    [cell configureWithEarthquake:earthquake];
    
	return cell;
}

/**
 * When the user taps a row in the table, display the USGS web page that displays details of the earthquake they selected.
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    // open the earthquake info in Maps, note this will not work in the simulator
    NSIndexPath *selectedIndexPath = (self.tableView).indexPathForSelectedRow;
    APLEarthquake *earthquake = (APLEarthquake *)self.earthQuakeSource.earthquakes[selectedIndexPath.row];
    
    // create a map region pointing to the earthquake location
    CLLocationCoordinate2D location = (CLLocationCoordinate2D) { earthquake.latitude, earthquake.longitude };
    NSValue *locationValue = [NSValue valueWithMKCoordinate:location];
    
    MKCoordinateSpan span = (MKCoordinateSpan) { 50, 50 };
    NSValue *spanValue = [NSValue valueWithMKCoordinateSpan:span];
    
    NSDictionary *launchOptions = @{ MKLaunchOptionsMapTypeKey : @(MKMapTypeStandard),
                                     MKLaunchOptionsMapCenterKey : locationValue,
                                     MKLaunchOptionsMapSpanKey : spanValue,
                                     MKLaunchOptionsShowsTrafficKey : @(NO),
                                     MKLaunchOptionsDirectionsModeDriving : @(NO) };
    
    // make sure the map item has a pin placed on it with the title as the earthquake location
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:location
                                                   addressDictionary:nil];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    mapItem.name = earthquake.location;
    [mapItem openInMapsWithLaunchOptions:launchOptions];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    APLEarthQuakeSource *earthQuakeSource = object;
    
    if ([keyPath isEqualToString:@"earthquakes"])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [self.tableView reloadData];
        });
    }
    else if ([keyPath isEqualToString:@"error"])
    {
        /* Handle errors in the download by showing an alert to the user. This is a very simple way of handling the error, partly because this application does not have any offline functionality for the user. Most real applications should handle the error in a less obtrusive way and provide offline functionality to the user.
            */
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            NSError *error = earthQuakeSource.error;
        
            NSString *errorMessage = error.localizedDescription;
            NSString *alertTitle = NSLocalizedString(@"Error", @"Title for alert displayed when download or parse error occurs.");
            NSString *okTitle = NSLocalizedString(@"OK", @"OK Title for alert displayed when download or parse error occurs.");
            
            _alert = [UIAlertController alertControllerWithTitle:alertTitle message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
                //..
            }];
            [self.alert addAction:action];
            
            if (self.presentedViewController == nil) {
                [self presentViewController:self.alert animated:YES completion:^ {
                    //..
                }];
            }
        });
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

