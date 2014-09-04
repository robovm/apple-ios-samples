/*
     File: RegionsViewController.m
 Abstract: This controller manages the CLLocationManager for location updates and switches the interface between showing the region map and the updates table list. This controller also manages adding and removing regions to be monitored by the application.
  Version: 1.1
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "RegionsViewController.h"
#import "RegionAnnotationView.h"
#import "RegionAnnotation.h"

@implementation RegionsViewController

@synthesize regionsMapView, updatesTableView, updateEvents, locationManager, navigationBar;

#pragma mark - Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)dealloc {
	[updateEvents release];
	self.locationManager.delegate = nil;
	[locationManager release];
	[regionsMapView release];
	[updatesTableView release];
	[navigationBar release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Create empty array to add region events to.
	updateEvents = [[NSMutableArray alloc] initWithCapacity:0];
	
	// Create location manager with filters set for battery efficiency.
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	locationManager.distanceFilter = kCLLocationAccuracyHundredMeters;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	
	// Start updating location changes.
	[locationManager startUpdatingLocation];
}


- (void)viewDidAppear:(BOOL)animated {
	// Get all regions being monitored for this application.
	NSArray *regions = [[locationManager monitoredRegions] allObjects];
	
	// Iterate through the regions and add annotations to the map for each of them.
	for (int i = 0; i < [regions count]; i++) {
		CLRegion *region = [regions objectAtIndex:i];
		RegionAnnotation *annotation = [[RegionAnnotation alloc] initWithCLRegion:region];
		[regionsMapView addAnnotation:annotation];
		[annotation release];
	}
}


- (void)viewDidUnload {
	self.updateEvents = nil;
	self.locationManager.delegate = nil;
	self.locationManager = nil;
	self.regionsMapView = nil;
	self.updatesTableView = nil;
	self.navigationBar = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [updateEvents count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
	cell.textLabel.font = [UIFont systemFontOfSize:12.0];
	cell.textLabel.text = [updateEvents objectAtIndex:indexPath.row];
	cell.textLabel.numberOfLines = 4;
	
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 60.0;
}


#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {	
	if([annotation isKindOfClass:[RegionAnnotation class]]) {
		RegionAnnotation *currentAnnotation = (RegionAnnotation *)annotation;
		NSString *annotationIdentifier = [currentAnnotation title];
		RegionAnnotationView *regionView = (RegionAnnotationView *)[regionsMapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];	
		
		if (!regionView) {
			regionView = [[[RegionAnnotationView alloc] initWithAnnotation:annotation] autorelease];
			regionView.map = regionsMapView;
			
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


- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
	if([overlay isKindOfClass:[MKCircle class]]) {
		// Create the view for the radius overlay.
		MKCircleView *circleView = [[[MKCircleView alloc] initWithOverlay:overlay] autorelease];
		circleView.strokeColor = [UIColor purpleColor];
		circleView.fillColor = [[UIColor purpleColor] colorWithAlphaComponent:0.4];
		
		return circleView;		
	}
	
	return nil;
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
	if([annotationView isKindOfClass:[RegionAnnotationView class]]) {
		RegionAnnotationView *regionView = (RegionAnnotationView *)annotationView;
		RegionAnnotation *regionAnnotation = (RegionAnnotation *)regionView.annotation;
		
		// If the annotation view is starting to be dragged, remove the overlay and stop monitoring the region.
		if (newState == MKAnnotationViewDragStateStarting) {		
			[regionView removeRadiusOverlay];
			
			[locationManager stopMonitoringForRegion:regionAnnotation.region];
		}
		
		// Once the annotation view has been dragged and placed in a new location, update and add the overlay and begin monitoring the new region.
		if (oldState == MKAnnotationViewDragStateDragging && newState == MKAnnotationViewDragStateEnding) {
			[regionView updateRadiusOverlay];
			
			CLRegion *newRegion = [[CLRegion alloc] initCircularRegionWithCenter:regionAnnotation.coordinate radius:1000.0 identifier:[NSString stringWithFormat:@"%f, %f", regionAnnotation.coordinate.latitude, regionAnnotation.coordinate.longitude]];
			regionAnnotation.region = newRegion;
			[newRegion release];
			
			[locationManager startMonitoringForRegion:regionAnnotation.region desiredAccuracy:kCLLocationAccuracyBest];
		}		
	}	
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
	RegionAnnotationView *regionView = (RegionAnnotationView *)view;
	RegionAnnotation *regionAnnotation = (RegionAnnotation *)regionView.annotation;
	
	// Stop monitoring the region, remove the radius overlay, and finally remove the annotation from the map.
	[locationManager stopMonitoringForRegion:regionAnnotation.region];
	[regionView removeRadiusOverlay];
	[regionsMapView removeAnnotation:regionAnnotation];
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"didFailWithError: %@", error);
}


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	NSLog(@"didUpdateToLocation %@ from %@", newLocation, oldLocation);
	
	// Work around a bug in MapKit where user location is not initially zoomed to.
	if (oldLocation == nil) {
		// Zoom to the current user location.
		MKCoordinateRegion userLocation = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 1500.0, 1500.0);
		[regionsMapView setRegion:userLocation animated:YES];
	}
}


- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region  {
	NSString *event = [NSString stringWithFormat:@"didEnterRegion %@ at %@", region.identifier, [NSDate date]];
	
	[self updateWithEvent:event];
}


- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
	NSString *event = [NSString stringWithFormat:@"didExitRegion %@ at %@", region.identifier, [NSDate date]];
	
	[self updateWithEvent:event];
}


- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
	NSString *event = [NSString stringWithFormat:@"monitoringDidFailForRegion %@: %@", region.identifier, error];
	
	[self updateWithEvent:event];
}


#pragma mark - RegionsViewController

/*
 This method swaps the visibility of the map view and the table of region events.
 The "add region" button in the navigation bar is also altered to only be enabled when the map is shown.
 */
- (IBAction)switchViews {
	// Swap the hidden status of the map and table view so that the appropriate one is now showing.
	self.regionsMapView.hidden = !self.regionsMapView.hidden;
	self.updatesTableView.hidden = !self.updatesTableView.hidden;
	
	// Adjust the "add region" button to only be enabled when the map is shown.
	NSArray *navigationBarItems = [NSArray arrayWithArray:self.navigationBar.items];
	UIBarButtonItem *addRegionButton = [[navigationBarItems objectAtIndex:0] rightBarButtonItem];
	addRegionButton.enabled = !addRegionButton.enabled;
	
	// Reload the table data and update the icon badge number when the table view is shown.
	if (!updatesTableView.hidden) {
		[updatesTableView reloadData];
	}
}

/*
 This method creates a new region based on the center coordinate of the map view.
 A new annotation is created to represent the region and then the application starts monitoring the new region.
 */
- (IBAction)addRegion {
	if ([CLLocationManager regionMonitoringAvailable]) {
		// Create a new region based on the center of the map view.
		CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(regionsMapView.centerCoordinate.latitude, regionsMapView.centerCoordinate.longitude);
		CLRegion *newRegion = [[CLRegion alloc] initCircularRegionWithCenter:coord 
																	  radius:1000.0 
																  identifier:[NSString stringWithFormat:@"%f, %f", regionsMapView.centerCoordinate.latitude, regionsMapView.centerCoordinate.longitude]];
		
		// Create an annotation to show where the region is located on the map.
		RegionAnnotation *myRegionAnnotation = [[RegionAnnotation alloc] initWithCLRegion:newRegion];
		myRegionAnnotation.coordinate = newRegion.center;
		myRegionAnnotation.radius = newRegion.radius;
		
		[regionsMapView addAnnotation:myRegionAnnotation];
		
		[myRegionAnnotation release];
		
		// Start monitoring the newly created region.
		[locationManager startMonitoringForRegion:newRegion desiredAccuracy:kCLLocationAccuracyBest];
		
		[newRegion release];
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
	[updateEvents insertObject:event atIndex:0];
	
	// Update the icon badge number.
	[UIApplication sharedApplication].applicationIconBadgeNumber++;
	
	if (!updatesTableView.hidden) {
		[updatesTableView reloadData];
	}
}


@end
