/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    pp delegate. Ties everything together, and handles some high-level UI input.
*/

#import "oalTouchAppDelegate.h"
#import "oalPlayback.h"

@interface oalTouchAppDelegate ()
@property (nonatomic, retain) IBOutlet UIViewController *viewController;
@end

@implementation oalTouchAppDelegate

@synthesize view;
@synthesize playback;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{

	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
	// Get accelerometer updates at 15 hz
    motionManager = [CMMotionManager new];
    motionManager.accelerometerUpdateInterval = (1.0 / 15.);
}

- (void)dealloc
{
    [motionManager stopAccelerometerUpdates];
    [motionManager release];
	[playback release];
	[view release];
	[_window release];
	[super dealloc];
}

- (IBAction)playPause:(UIButton *)sender
{
	// Toggle the playback
	
	if (playback.isPlaying) [playback stopSound];
	else [playback startSound];
	sender.selected = playback.isPlaying;
}

- (IBAction)toggleAccelerometer:(UISwitch *)sender
{
	// Toggle the accelerometer
	// Note: With the accelerometer on, the device should be held vertically, not laid down flat.
	// As the device is rotated, the orientation of the listener will adjust so as as to be looking upward.
	if (sender.on) {
        [motionManager startAccelerometerUpdatesToQueue:[[[NSOperationQueue alloc] init] autorelease]
                                            withHandler:^(CMAccelerometerData *data, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat zRot;
	
            // Find out the Z rotation of the device by doing some trig on the accelerometer values for X and Y
            zRot = (atan2(data.acceleration.x, data.acceleration.y) + M_PI);
	
            // Set our listener's rotation
            playback.listenerRotation = zRot;
        });
      }
        ];
	} else {
        [motionManager stopAccelerometerUpdates];
	}
}

@end
