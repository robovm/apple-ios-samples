/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller displays a map with annotations if the app has access to Reminders and an empty map, otherwise.
            Tap any annotation's callout to create a reminder for that location.
 */

#import "MyAnnotation.h"
#import "EKRSConstants.h"
#import "EKRSHelperClass.h"
#import "MapViewController.h"
#import "AddLocationReminder.h"
#import "LocationReminderStore.h"
#import "LocationTabBarController.h"

const double EKLRRegionDelta = 2.12;
const double EKLRRegionLatitude = 37.78699;
const double EKLRRegionLongitude = -122.4401;


static NSString *const EKRSAnnotationAddress = @"address";
static NSString *const EKRSAnnotationLatitude = @"latitude";
static NSString *const EKRSAnnotationLongitude = @"longitude";


static NSString *EKLRLocationsList = @"Locations";
static NSString *EKLRLocationsListExtension = @"plist";
static NSString * const kPinAnnotationViewIdentifier = @"pinAnnotationViewIdentifier";


@interface MapViewController () <CLLocationManagerDelegate>
@property (nonatomic)id<MKAnnotation> selectedAnnotation;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) EKStructuredLocation  *selectedStructureLocation;
@property (nonatomic, copy) NSString *currentUserLocationAddress;

@end

@implementation MapViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleLTBControllerNotification:)
                                                     name:LTBAccessGrantedNotification
                                                   object:nil];
        
    }
    return self;
}


#pragma mark - Location Access Methods

- (void)checkLocationServicesAuthorizationStatus
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    switch (status)
    {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self accessGrantedForLocationServices];
            break;
        case  kCLAuthorizationStatusNotDetermined :
            [self requestLocationServicesAuthorization];
            break;
        case  kCLAuthorizationStatusDenied:
        case  kCLAuthorizationStatusRestricted:
        {
            if (self.mapView.annotations > 0)
            {
                [self.mapView removeAnnotations:[NSArray arrayWithArray:self.mapView.annotations]];
            }
            
            UIAlertController *alert = [EKRSHelperClass alertWithTitle:NSLocalizedString(@"Privacy Warning", nil)
                                                               message:NSLocalizedString(@"Access was not granted for Location Services.", nil)];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
            
            break;
        default:
            break;
    }
}


-(void)requestLocationServicesAuthorization
{
    if (self.locationManager == nil)
    {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
    
    // Ask for user permission to find our location
    [self.locationManager requestWhenInUseAuthorization];
}



#pragma mark - Handle LocationTabBarController Notification

-(void)handleLTBControllerNotification:(NSNotification *)notification
{
    [self accessGrantedForReminders];
}


#pragma mark - Handle Location Services Access

/*
 
 This sample uses data from the Locations.plist file to create annotations for the map. Locations.plist includes an array of dictionaries
 that each represents the title, latitude, longitude, and address information of an annotation. Additionally, accessGrantedForLocationServices
 adds the current user location to Map. Update this file with data formatted as described above if you wish to test reminders around other locations.
 Note that you can obtain latitude, longitude, and delta information by following these steps:
 1) Implement
 - (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
 
 2) Zoom or pan to the area you want in Map, then set a breakpoint there to obtain information about the region.
 
 3) Display the latitude, longitude, and delta information by executing po mapview.region in the debugger.
 
 */

-(void)accessGrantedForLocationServices
{
    
    if (self.mapView.annotations > 0)
    {
        [self.mapView removeAnnotations:[NSArray arrayWithArray:self.mapView.annotations]];
    }
    
    // Locations.plist contains all data required for configuring the map's region and points of interest
    NSURL *plistURL = [[NSBundle mainBundle] URLForResource:EKLRLocationsList withExtension:EKLRLocationsListExtension];
    NSArray *data = [NSArray arrayWithContentsOfURL:plistURL];
    
    
    [self.mapView addAnnotations:[self fetchAnnotations:data]];
    self.mapView.showsUserLocation = YES;
}


#pragma mark - Handle Reminders Access


-(void)accessGrantedForReminders
{
    [self checkLocationServicesAuthorizationStatus];
}


#pragma mark - Fetch Interest Points

-(NSMutableArray *)fetchAnnotations:(NSArray *)locations
{
    NSMutableArray *annotations = [[NSMutableArray alloc] initWithCapacity:locations.count];
    
    for (NSDictionary *dict in locations)
    {
        MyAnnotation *myAnnotation = [[MyAnnotation alloc]initWithTitle:dict[EKRSTitle]
                                                               latitude:[dict[EKRSAnnotationLatitude] doubleValue]
                                                              longitude:[dict[EKRSAnnotationLongitude] doubleValue]
                                                                address:dict[EKRSAnnotationAddress]];
        
        
        [annotations addObject:myAnnotation];
    }
    
    return annotations;
}



#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@",error.description);
}


// Called when the authorization status changes for Location Services
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    // Check the authorization status and take the appropriate action
    [self checkLocationServicesAuthorizationStatus];
}


#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude: userLocation.coordinate.latitude longitude:userLocation.coordinate.longitude];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    // Reverse-geocode the current user coordinates
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if ((placemarks != nil) && (placemarks.count > 0))
        {
            CLPlacemark *placemark = placemarks.firstObject;
            self.currentUserLocationAddress = [NSString stringWithFormat:@"%@ %@ %@",placemark.subThoroughfare, placemark.thoroughfare,placemark.locality];
        }
    }];
    
    // Create a region using the current user location
    MKCoordinateRegion region;
    region.span = MKCoordinateSpanMake(EKLRRegionDelta, EKLRRegionDelta);
    region.center = CLLocationCoordinate2DMake(userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);
    [self.mapView setRegion:region animated:YES];
}


- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKPinAnnotationView *pinView =(MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:kPinAnnotationViewIdentifier];
    if (!pinView)
    {
        pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                  reuseIdentifier:kPinAnnotationViewIdentifier];
        
        if ([pinView respondsToSelector:@selector(pinTintColor)])
        {
            ((MKPinAnnotationView *)pinView).pinTintColor = [MKPinAnnotationView purplePinColor];
        }
        else
        {
            // ignore this compile warning, since we already have implemented the replacement above
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            ((MKPinAnnotationView *)pinView).pinColor = MKPinAnnotationColorPurple;
#pragma GCC diagnostic pop
        }
        pinView.animatesDrop = YES;
        pinView.canShowCallout = YES;
        
        pinView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }
    else
    {
        pinView.annotation = annotation;
    }
    return pinView;
    
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"LocationReminders" bundle:nil];
    UINavigationController *navigationController = (UINavigationController *)[story instantiateViewControllerWithIdentifier:@"navAddLocationReminderVCID"];
    
    
    AddLocationReminder *addLocationReminderViewController = (AddLocationReminder *)navigationController.topViewController;
    
    if ([view.annotation isKindOfClass:[MyAnnotation class]])
    {
        MyAnnotation *myAnnotation = (MyAnnotation *)view.annotation;
        
        addLocationReminderViewController.name = myAnnotation.title;
        addLocationReminderViewController.address = myAnnotation.address;
    }
    else
    {
        MKUserLocation *userLocation = view.annotation;
        // We selected the user location
        addLocationReminderViewController.name = userLocation.title;
        addLocationReminderViewController.address =  self.currentUserLocationAddress;
    }
    
    self.selectedAnnotation = view.annotation;
    
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}


- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
}


#pragma mark - Unwind Segues

// Dismiss the Add Location Reminder view controller
- (IBAction)cancel:(UIStoryboardSegue*)sender
{
}


- (IBAction)done:(UIStoryboardSegue*)sender
{
    AddLocationReminder *addLocationReminderViewController = (AddLocationReminder *)sender.sourceViewController;
    
    NSDictionary *dictionary = addLocationReminderViewController.userInput;
    
    // If the selected annotation is the current user location, show its address rather than Current Location. Show its title, otherwise.
    EKStructuredLocation *location = ([self.selectedAnnotation isKindOfClass:[MKUserLocation class]]) ? [EKStructuredLocation locationWithTitle:self.currentUserLocationAddress] :[EKStructuredLocation locationWithTitle:self.selectedAnnotation.title];
    
    
    location.geoLocation = [[CLLocation alloc] initWithLatitude:self.selectedAnnotation.coordinate.latitude
                                                      longitude:self.selectedAnnotation.coordinate.longitude];
    
    // Convert from miles to meters before assigning it to the radius property
    location.radius = kMeter *[dictionary[EKRSLocationRadius] doubleValue];
    
    
    LocationReminder *newLocationReminder = [[LocationReminder alloc] initWithTitle:dictionary[EKRSTitle]
                                                                          proximity:dictionary[EKRSLocationProximity]
                                                                  structureLocation:location];
    
    
    [[LocationReminderStore sharedInstance] createLocationReminder:newLocationReminder];
}


#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:LTBAccessGrantedNotification
                                                  object:nil];
}

@end
