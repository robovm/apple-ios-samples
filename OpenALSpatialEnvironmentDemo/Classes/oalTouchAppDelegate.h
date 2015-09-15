/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    pp delegate. Ties everything together, and handles some high-level UI input.
*/

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@class oalSpatialView;
@class oalPlayback;

@interface oalTouchAppDelegate : NSObject <UIApplicationDelegate, UIAccelerometerDelegate> {
	//IBOutlet UIWindow*			window;
	IBOutlet oalSpatialView*	view;
	IBOutlet oalPlayback*		playback;
    CMMotionManager*            motionManager;
}

@property (nonatomic, retain) UIWindow*			window;

@property (nonatomic, retain) oalSpatialView*	view; 
@property (nonatomic, retain) oalPlayback*		playback;

- (IBAction)playPause:(UIButton*)sender;
- (IBAction)toggleAccelerometer:(UISwitch*)sender;

@end

