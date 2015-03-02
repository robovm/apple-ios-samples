/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This view controller lets you query for items near the location of the pin.
  
 */

#import "AAPLLocationQueryViewController.h"
#import "AAPLCloudManager.h"

@import MapKit;

@interface AAPLLocationQueryViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property (nonatomic, strong) MKPointAnnotation *pin;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, copy) NSArray *results;

@property (weak) IBOutlet MKMapView *map;

@end

@implementation AAPLLocationQueryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.map.delegate = self;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    self.currentLocation = locations.lastObject;
    
    if (!self.pin) {
        self.pin = [[MKPointAnnotation alloc]init];
        self.pin.coordinate = self.currentLocation.coordinate;
        
        [self.map addAnnotation:self.pin];
        [self.map showAnnotations:@[self.pin] animated:NO];
        
        [self.locationManager stopUpdatingLocation];
    }
}

- (IBAction)queryRecords:(id)sender {
    CLLocation *queryLocation = [[CLLocation alloc] initWithLatitude:self.pin.coordinate.latitude
                                                           longitude:self.pin.coordinate.longitude];
    
    [self.cloudManager queryForRecordsNearLocation:queryLocation completionHandler:^(NSArray *records) {
        self.results = records;
        [self.tableView reloadData];
    }];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    CKRecord *record = self.results[indexPath.row];
    cell.textLabel.text = record[NameField];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CKRecord *record = self.results[indexPath.row];
    CLLocation *recordLocation = record[LocationField];
    self.pin.coordinate = recordLocation.coordinate;
    [self.map addAnnotation:self.pin];
    [self.map showAnnotations:@[self.pin] animated:NO];
}

#pragma mark - Map View Delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKPinAnnotationView *view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];

    view.draggable = YES;
    
    return view;
}

@end
