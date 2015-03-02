/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This view controller lets you add items with a name and a location.
  
 */

@import MapKit;

#import "AAPLCKRecordViewController.h"
#import "AAPLCloudManager.h"

@interface AAPLCKRecordViewController() <CLLocationManagerDelegate, MKMapViewDelegate>

@property (nonatomic, strong) MKPointAnnotation *pin;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (weak) IBOutlet UITextField *nameTextField;
@property (weak) IBOutlet MKMapView *map;

@end

@implementation AAPLCKRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
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

- (IBAction)saveRecord:(id)sender {
    if (self.nameTextField.text.length < 1) {
        
        [self.nameTextField resignFirstResponder];
        return;
    }
    
    CLLocation *saveLocation = [[CLLocation alloc] initWithLatitude:self.pin.coordinate.latitude longitude:self.pin.coordinate.longitude];

    __weak __typeof(self) weakSelf = self;
    [self.cloudManager addRecordWithName:self.nameTextField.text location:saveLocation completionHandler:^(CKRecord *record) {
        typeof(self) strongSelf = weakSelf;

        if (record) {
            strongSelf.nameTextField.text = @"";
            [strongSelf.nameTextField resignFirstResponder];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"CloudKitAtlas" message:@"Saved record." preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
                [strongSelf dismissViewControllerAnimated:YES completion:nil];
            }];
            
            [alert addAction:action];
            [strongSelf presentViewController:alert animated:YES completion:nil];
            
        } else {
            NSLog(@"Error: nil returned on save.");
        }
    }];
}

#pragma mark - Map View Delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKPinAnnotationView *view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
    
    view.draggable = YES;

    return view;
}

@end
