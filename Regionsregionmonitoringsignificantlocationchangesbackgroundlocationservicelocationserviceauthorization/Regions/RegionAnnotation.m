/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The annotation to represent a region that is being monitored.
 */

#import "RegionAnnotation.h"

@interface RegionAnnotation()

@property (nonatomic, copy) NSString *subtitle;

@end

@implementation RegionAnnotation

// Initialize the annotation object.
- (instancetype)init {
	self = [super init];
	if (self != nil) {
		_title = @"Monitored Region";
	}
	
	return self;	
}

// Initialize the annotation object with the monitored region.
- (instancetype)initWithCLRegion:(CLCircularRegion *)newRegion {
	self = [self init];
	
	if (self != nil) {
        
		_region = newRegion;
		_coordinate = newRegion.center;
		_radius = newRegion.radius;
		_title = @"Monitored Region";
	}		

	return self;		
}


/*
 This method provides a custom setter so that the model is notified when the subtitle value has changed, which is derived from the radius.
 */
- (void)setRadius:(CLLocationDistance)newRadius {
	[self willChangeValueForKey:@"subtitle"];
	
	_radius = newRadius;
	
	[self didChangeValueForKey:@"subtitle"];
}


- (NSString *)subtitle {
	return [NSString stringWithFormat: @"Lat: %.4F, Lon: %.4F, Rad: %.1fm", self.coordinate.latitude, self.coordinate.longitude, self.radius];
}




@end
