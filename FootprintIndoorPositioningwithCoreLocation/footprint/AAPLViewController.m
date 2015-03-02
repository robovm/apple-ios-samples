/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Primary view controller for what is displayed by the application.
                In this class we receieve location updates from Core Location, convert them to x,y coordinates so that they map on the imageView
                and move the pinView to that location
            
*/

#import "AAPLViewController.h"
#import "AAPLCoordinateConverter.h"

@interface AAPLViewController () <CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIImageView *pinView;
@property (nonatomic, weak) IBOutlet UIImageView *radiusView;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) AAPLCoordinateConverter *coordinateConverter;

@property CGFloat displayScale;
@property CGPoint displayOffset;

@property (nonatomic) AAPLGeoAnchorPair anchorPair;

@end

@implementation AAPLViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	// Setup a reference to location manager.
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.delegate = self;
	self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.activityType = CLActivityTypeOther;

	// We setup a pair of anchors that will define how the floorplan image, maps to geographic co-ordinates
    AAPLGeoAnchor anchor1 = {
        .latitudeLongitude = CLLocationCoordinate2DMake(37.770511, -122.465810),
        .pixel = CGPointMake(12, 18)
    };

    AAPLGeoAnchor anchor2 = {
        .latitudeLongitude = CLLocationCoordinate2DMake(37.769125, -122.466356),
        .pixel = CGPointMake(481, 815)
    };

    self.anchorPair = (AAPLGeoAnchorPair) {
        .fromAnchor = anchor1,
        .toAnchor = anchor2
    };

	// Initialize the coordinate system converter with two anchor points.
	self.coordinateConverter = [[AAPLCoordinateConverter alloc] initWithAnchors:self.anchorPair];
}

- (void)viewDidAppear:(BOOL)animated {
    [self setScaleAndOffset];
    [self startTrackingLocation];
}

- (void) setScaleAndOffset {
    CGSize imageViewFrameSize = self.imageView.frame.size;
    CGSize imageSize = self.imageView.image.size;

    // Calculate how much we'll be scaling the image to fit on screen.
    self.displayScale = MIN(imageViewFrameSize.width / imageSize.width, imageViewFrameSize.height / imageSize.height);
    NSLog(@"Scale Factor: %f", self.displayScale);

    // Depending on whether we're constrained by width or height,
    // figure out how much our floorplan pixels need to be offset to adjust for the image being centered
    if (imageViewFrameSize.width / imageSize.width < imageViewFrameSize.height / imageSize.height) {
        NSLog(@"Constrained by width");
        self.displayOffset = CGPointMake(0, (imageViewFrameSize.height - imageSize.height * self.displayScale) / 2);
    } else {
        NSLog(@"Constrained by height");
        self.displayOffset = CGPointMake((imageViewFrameSize.width - imageSize.width * self.displayScale) / 2, 0);
    }

    NSLog(@"Offset: %f, %f", self.displayOffset.x, self.displayOffset.y);
}

- (void)startTrackingLocation {
	CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
		[self.locationManager requestWhenInUseAuthorization];
    }
    else if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
		[self.locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	switch (status) {
		case kCLAuthorizationStatusAuthorizedAlways:
		case kCLAuthorizationStatusAuthorizedWhenInUse:
			NSLog(@"Got authorization, start tracking location");
			[self startTrackingLocation];
            break;
		case kCLAuthorizationStatusNotDetermined:
			[self.locationManager requestWhenInUseAuthorization];
		default:
			break;
	}
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    // Pass location updates to the map view.
	[locations enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
        NSLog(@"Location (Floor %@): %@", location.floor, location.description);
		[self updateViewWithLocation:location];
	}];
}

- (void) updateViewWithLocation: (CLLocation *) location {
	// We animate transition from one position to the next, this makes the dot move smoothly over the map
	[UIView animateWithDuration:0.75 animations:^ {
		// Call the converter to find these coordinates on our floorplan.
		CGPoint pointOnImage = [self.coordinateConverter pointFromCoordinate:location.coordinate];

		// These coordinates need to be scaled based on how much the image has been scaled
		CGPoint scaledPoint = CGPointMake(pointOnImage.x * self.displayScale + self.displayOffset.x,
										  pointOnImage.y * self.displayScale + self.displayOffset.y);

		// Calculate and set the size of the radius
		CGFloat radiusFrameSize = location.horizontalAccuracy * self.coordinateConverter.pixelsPerMeter * 2;
		self.radiusView.frame = CGRectMake(0, 0, radiusFrameSize, radiusFrameSize);

		// Move the pin and radius to the user's location
		self.pinView.center = scaledPoint;
		self.radiusView.center = scaledPoint;
	}];
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	// Upon rotation, we want to resize the image and center it appropriately.
    [self setScaleAndOffset];
}

@end
