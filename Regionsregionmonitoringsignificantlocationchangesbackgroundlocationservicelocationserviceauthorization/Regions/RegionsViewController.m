/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller displays the map and allows the user to set regions to monitor.
 */

#import "RegionsViewController.h"
#import "RegionAnnotationView.h"
#import "RegionAnnotation.h"

@interface RegionsViewController() <UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, CLLocationManagerDelegate, UINavigationBarDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *regionsMapView;
@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;

@property (nonatomic, strong) NSMutableArray *updateEvents;

@end

@implementation RegionsViewController

#pragma mark - Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)dealloc {
	self.locationManager.delegate = nil;
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Create empty array to add region events to.
	self.updateEvents = [[NSMutableArray alloc] initWithCapacity:0];
	
	// Create location manager early, so we can check and ask for location services authorization.
	self.locationManager = [[CLLocationManager alloc] init];
    // Configure the location manager.
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLLocationAccuracyHundredMeters;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // Define a weak self reference.
    RegionsViewController * __weak weakSelf = self;
    
    // Subscribe to app state change notifications, so we can stop/start location services.
    
    // When our app is interrupted, stop the standard location service,
    // and start significant location change service, if available.
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
            // Stop normal location updates and start significant location change updates for battery efficiency.
            [weakSelf.locationManager stopUpdatingLocation];
            [weakSelf.locationManager startMonitoringSignificantLocationChanges];
        }
        else {
            NSLog(@"Significant location change monitoring is not available.");
        }
    }];
    
    // Stop the significant location change service, if available,
    // and start the standard location service.
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
            // Stop significant location updates and start normal location updates again since the app is in the forefront.
            [weakSelf.locationManager stopMonitoringSignificantLocationChanges];
            [weakSelf.locationManager startUpdatingLocation];
        }
        else {
            NSLog(@"Significant location change monitoring is not available.");
        }
        
        if (!weakSelf.updatesTableView.hidden) {
            // Reload the updates table view to reflect update events that were recorded in the background.
            [weakSelf.updatesTableView reloadData];
            
            // Reset the icon badge number to zero.
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        }
    }];
}


- (void)viewDidAppear:(BOOL)animated {
    
    // Request always allowed location service authorization.
    // This is done here, so we can display an alert if the user has denied location services previously
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        // If status is not determined, then we should ask for authorization.
        [self.locationManager requestAlwaysAuthorization];
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        // If authorization has been denied previously, inform the user.
        NSLog(@"%s: location services authorization was previously denied by the user.", __PRETTY_FUNCTION__);
        
        // Display alert to the user.
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Location services" message:@"Location services were previously denied by the user. Please enable location services for this app in settings." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}]; // Do nothing action to dismiss the alert.
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    } else { // We do have authorization.
        // Start the standard location service.
        [self.locationManager startUpdatingLocation];
    }

    // Set the map's user tracking mode.
    self.regionsMapView.userTrackingMode = MKUserTrackingModeNone;
    
	// Get all regions being monitored for this application.
	NSArray *regions = [[self.locationManager monitoredRegions] allObjects];
	
	// Iterate through the regions and add annotations to the map for each of them.
	for (int i = 0; i < [regions count]; i++) {
		CLRegion *region = regions[i];
		RegionAnnotation *annotation = [[RegionAnnotation alloc] initWithCLRegion:region];
		[self.regionsMapView addAnnotation:annotation];
	}
}

// Do some clean up when being deallocated.
- (void)viewDidUnload {
	self.updateEvents = nil;
	self.locationManager.delegate = nil;
	self.locationManager = nil;
	self.regionsMapView = nil;
	self.updatesTableView = nil;
	self.navigationBar = nil;
}

#pragma mark - UITableViewDelegate

// Return the number of section, which is one.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Return the number of rows in the one and only section.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.updateEvents count];
}

// Dequeue and return a table view cell to be displayed in the table view.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
	cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	cell.textLabel.text = (self.updateEvents)[indexPath.row];
	cell.textLabel.numberOfLines = 4;
	
    return cell;
}

// Return the height we want for the table view cells.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 60.0;
}


#pragma mark - MKMapViewDelegate

// Return the view for the region annotation callout.
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {	
	if([annotation isKindOfClass:[RegionAnnotation class]]) {
		RegionAnnotation *currentAnnotation = (RegionAnnotation *)annotation;
		NSString *annotationIdentifier = [currentAnnotation title];
		RegionAnnotationView *regionView = (RegionAnnotationView *)[self.regionsMapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
		
		if (!regionView) {
			regionView = [[RegionAnnotationView alloc] initWithAnnotation:annotation];
			regionView.map = self.regionsMapView;
			
			// Create a button for the left callout accessory view of each annotation to remove the annotation and region being monitored.
			UIButton *removeRegionButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[removeRegionButton setFrame:CGRectMake(0., 0., 25., 25.)];
			[removeRegionButton setImage:[UIImage imageNamed:@"RemoveRegion"] forState:UIControlStateNormal];
			
			regionView.leftCalloutAccessoryView = removeRegionButton;
		} else {		
			regionView.annotation = annotation;
			regionView.theAnnotation = annotation;
		}
		
		// Update or add the overlay displaying the radius of the region around the annotation.
		[regionView updateRadiusOverlay];
		
		return regionView;		
	}	
	
	return nil;	
}

// Return the map overlay that depicts the region.
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
	if([overlay isKindOfClass:[MKCircle class]]) {
		// Create the view for the circular overlay.
		MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
		circleView.strokeColor = [UIColor purpleColor];
		circleView.fillColor = [[UIColor purpleColor] colorWithAlphaComponent:0.4];
		
		return circleView;		
	}
	
	return nil;
}

// Enable the user to reposition the pins representing the regions by dragging them.
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
	if([annotationView isKindOfClass:[RegionAnnotationView class]]) {
		RegionAnnotationView *regionView = (RegionAnnotationView *)annotationView;
		RegionAnnotation *regionAnnotation = (RegionAnnotation *)regionView.annotation;
		
		// If the annotation view is starting to be dragged, remove the overlay and stop monitoring the region.
		if (newState == MKAnnotationViewDragStateStarting) {		
			[regionView removeRadiusOverlay];
			
			[self.locationManager stopMonitoringForRegion:regionAnnotation.region];
		}
		
		// Once the annotation view has been dragged and placed in a new location, update and add the overlay and begin monitoring the new region.
		if (oldState == MKAnnotationViewDragStateDragging && newState == MKAnnotationViewDragStateEnding) {
			[regionView updateRadiusOverlay];
            
            CLCircularRegion *newRegion = [[CLCircularRegion alloc] initWithCenter:regionAnnotation.coordinate
                                                                            radius:1000.0
                                                                        identifier:[NSString stringWithFormat:@"%f, %f", regionAnnotation.coordinate.latitude, regionAnnotation.coordinate.longitude]];
			
			regionAnnotation.region = newRegion;
			
			[self.locationManager startMonitoringForRegion:regionAnnotation.region];
		}		
	}	
}

// The X was tapped on a region annotation, so remove that region form the map, and stop monitoring that region.
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
	RegionAnnotationView *regionView = (RegionAnnotationView *)view;
	RegionAnnotation *regionAnnotation = (RegionAnnotation *)regionView.annotation;
	
	// Stop monitoring the region, remove the radius overlay, and finally remove the annotation from the map.
	[self.locationManager stopMonitoringForRegion:regionAnnotation.region];
	[regionView removeRadiusOverlay];
	[self.regionsMapView removeAnnotation:regionAnnotation];
}


#pragma mark - CLLocationManagerDelegate

// When the user has granted authorization, start the standard location service.
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        // Start the standard location service.
        [self.locationManager startUpdatingLocation];
    }
}

// A core location error occurred.
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"didFailWithError: %@", error);
}

// The system delivered a new location.
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	
	// Work around a bug in MapKit where user location is not initially zoomed to.
	if (oldLocation == nil) {
		// Zoom to the current user location.
		MKCoordinateRegion userLocation = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 1500.0, 1500.0);
		[self.regionsMapView setRegion:userLocation animated:YES];
	}
}

// The device entered a monitored region.
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region  {
	NSString *event = [NSString stringWithFormat:@"didEnterRegion %@ at %@", region.identifier, [NSDate date]];
    NSLog(@"%s %@", __PRETTY_FUNCTION__, event);
	
	[self updateWithEvent:event];
}

// The device exited a monitored region.
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
	NSString *event = [NSString stringWithFormat:@"didExitRegion %@ at %@", region.identifier, [NSDate date]];
	NSLog(@"%s %@", __PRETTY_FUNCTION__, event);
    
	[self updateWithEvent:event];
}

// A monitoring error occurred for a region.
- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
	NSString *event = [NSString stringWithFormat:@"monitoringDidFailForRegion %@: %@", region.identifier, error];
	NSLog(@"%s %@", __PRETTY_FUNCTION__, event);
    
	[self updateWithEvent:event];
}


#pragma mark - RegionsViewController

/*
 This method swaps the visible view between the map view and the table of region events.
 The "add region" button in the navigation bar is also altered to only be enabled when the map is shown.
 */
- (IBAction)switchViews {
	// Swap the hidden status of the map and table view so that the appropriate one is now showing.
	self.regionsMapView.hidden = !self.regionsMapView.hidden;
	self.updatesTableView.hidden = !self.updatesTableView.hidden;
	
	// Adjust the "add region" button to only be enabled when the map is shown.
	NSArray *navigationBarItems = [NSArray arrayWithArray:self.navigationBar.items];
	UIBarButtonItem *addRegionButton = [navigationBarItems[0] rightBarButtonItem];
	addRegionButton.enabled = !addRegionButton.enabled;
	
	// Reload the table data and update the icon badge number when the table view is shown.
	if (!self.updatesTableView.hidden) {
		[self.updatesTableView reloadData];
	}
}


/*
 This method creates a new region based on the center coordinate of the map view.
 A new annotation is created to represent the region and then the application starts monitoring the new region.
 */
- (IBAction)addRegion {
	if ([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
		// Create a new region based on the center of the map view.
		CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(self.regionsMapView.centerCoordinate.latitude, self.regionsMapView.centerCoordinate.longitude);
        CLCircularRegion *newRegion = [[CLCircularRegion alloc] initWithCenter:coord
                                                                        radius:1000.0
                                                                    identifier:[NSString stringWithFormat:@"%f, %f", self.regionsMapView.centerCoordinate.latitude, self.regionsMapView.centerCoordinate.longitude]];
        newRegion.notifyOnEntry = YES;
        newRegion.notifyOnExit = YES;
        
		// Create an annotation to show where the region is located on the map.
		RegionAnnotation *myRegionAnnotation = [[RegionAnnotation alloc] initWithCLRegion:newRegion];
		myRegionAnnotation.coordinate = newRegion.center;
		myRegionAnnotation.radius = newRegion.radius;
		
		[self.regionsMapView addAnnotation:myRegionAnnotation];
		
		
		// Start monitoring the newly created region.
		[self.locationManager startMonitoringForRegion:newRegion];
		
	}
	else {
		NSLog(@"Region monitoring is not available.");
	}
}


/*
 This method adds the region event to the events array and updates the icon badge number.
 */
- (void)updateWithEvent:(NSString *)event {
	// Add region event to the updates array.
	[self.updateEvents insertObject:event atIndex:0];
	
	// Update the icon badge number.
	[UIApplication sharedApplication].applicationIconBadgeNumber++;
	
	if (!self.updatesTableView.hidden) {
		[self.updatesTableView reloadData];
	}
}


@end
