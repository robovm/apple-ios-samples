/*
    File: TeslameterViewController.m
Abstract: A view controller that manages the primary view within the application. It creates a CLLocationManager and turns on heading updates. As updates are received, it displays them in a graph, x, y, and z labels, and also computes the magnitude (size or strength) of the magnetic vector. The units for all values are microteslas.

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

Copyright (C) 2014 Apple Inc. All Rights Reserved.

*/

#import "TeslameterViewController.h"
#import "GraphView.h"

@interface TeslameterViewController ()

@property (nonatomic, retain) IBOutlet UILabel *magnitudeLabel;
@property (nonatomic, retain) IBOutlet UILabel *xLabel;
@property (nonatomic, retain) IBOutlet UILabel *yLabel;
@property (nonatomic, retain) IBOutlet UILabel *zLabel;
@property (nonatomic, retain) IBOutlet GraphView *graphView;

@property (nonatomic, retain) CLLocationManager *locationManager;

@end

#pragma mark -

@implementation TeslameterViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// setup the location manager
	_locationManager = [[CLLocationManager alloc] init];
	
	// check if the hardware has a compass
	if ([CLLocationManager headingAvailable] == NO) {
		// No compass is available. This application cannot function without a compass, 
        // so a dialog will be displayed and no magnetic data will be measured.
        self.locationManager = nil;
        UIAlertView *noCompassAlert = [[UIAlertView alloc] initWithTitle:@"No Compass!"
                                                                 message:@"This device does not have the ability to measure magnetic fields."
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
        [noCompassAlert show];
	} else {
        // heading service configuration
        self.locationManager.headingFilter = kCLHeadingFilterNone;
        
        // setup delegate callbacks
        self.locationManager.delegate = self;
        
        // start the compass
        [self.locationManager startUpdatingHeading];
    }
}

- (void)dealloc {
	// Stop the compass
	[self.locationManager stopUpdatingHeading];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    // Status bar text should be white.
    return UIStatusBarStyleLightContent;
}

// This delegate method is invoked when the location manager has heading data.
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)heading {
    // Update the labels with the raw x, y, and z values.
	self.xLabel.text = [NSString stringWithFormat:@"%.1f", heading.x];
	self.yLabel.text = [NSString stringWithFormat:@"%.1f", heading.y];
	self.zLabel.text = [NSString stringWithFormat:@"%.1f", heading.z];
    
    // Compute and display the magnitude (size or strength) of the vector.
	//      magnitude = sqrt(x^2 + y^2 + z^2)
	CGFloat magnitude = sqrt(heading.x*heading.x + heading.y*heading.y + heading.z*heading.z);
    [self.magnitudeLabel setText:[NSString stringWithFormat:@"%.1f", magnitude]];
	
	// Update the graph with the new magnetic reading.
	[self.graphView updateHistoryWithX:heading.x y:heading.y z:heading.z];
}

// This delegate method is invoked when the location managed encounters an error condition.
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if ([error code] == kCLErrorDenied) {
        // This error indicates that the user has denied the application's request to use location services.
        [manager stopUpdatingHeading];
    } else if ([error code] == kCLErrorHeadingFailure) {
        // This error indicates that the heading could not be determined, most likely because of strong magnetic interference.
    }
}

@end
