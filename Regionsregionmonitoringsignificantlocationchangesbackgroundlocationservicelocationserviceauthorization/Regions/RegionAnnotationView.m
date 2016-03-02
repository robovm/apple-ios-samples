/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The custom annotation view to display a region that is being monitored.
 */

#import "RegionAnnotationView.h"
#import "RegionAnnotation.h"

@interface RegionAnnotationView() {

}

@property (strong, nonatomic) MKCircle *radiusOverlay;
@property (assign, nonatomic) BOOL isRadiusUpdated;

@end

@implementation RegionAnnotationView

// Initialize the annotation view object. This is the designated initializer.
- (instancetype)initWithAnnotation:(id <MKAnnotation>)annotation {
	self = [super initWithAnnotation:annotation reuseIdentifier:[annotation title]];	
	
	if (self) {		
		self.canShowCallout	= YES;
		self.multipleTouchEnabled = NO;
		self.draggable = YES;
		self.animatesDrop = YES;
		_map = nil;
		_theAnnotation = (RegionAnnotation *)annotation;
		self.pinColor = MKPinAnnotationColorPurple;
		_radiusOverlay = [MKCircle circleWithCenterCoordinate:_theAnnotation.coordinate radius:_theAnnotation.radius];
		
		[_map addOverlay:self.radiusOverlay];
	}
	
	return self;	
}


- (void)removeRadiusOverlay {
	// Find the overlay for this annotation view and remove it if it has the same coordinates.
	for (id overlay in [self.map overlays]) {
		if ([overlay isKindOfClass:[MKCircle class]]) {						
			MKCircle *circleOverlay = (MKCircle *)overlay;			
			CLLocationCoordinate2D coord = circleOverlay.coordinate;
			
			if (coord.latitude == self.theAnnotation.coordinate.latitude && coord.longitude == self.theAnnotation.coordinate.longitude) {
				[self.map removeOverlay:overlay];
			}			
		}
	}
	
	self.isRadiusUpdated = NO;
}

// Update the circular overlay if the radius has changed.
- (void)updateRadiusOverlay {
	if (!self.isRadiusUpdated) {
		self.isRadiusUpdated = YES;
		
		[self removeRadiusOverlay];	
		
		self.canShowCallout = NO;
		
		[self.map addOverlay:[MKCircle circleWithCenterCoordinate:self.theAnnotation.coordinate radius:self.theAnnotation.radius]];
		
		self.canShowCallout = YES;		
	}
}




@end
