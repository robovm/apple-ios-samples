/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  View Controller for Metal Sample Code. Maintains a CADisplayLink timer that runs on the main thread and triggers rendering in AAPLView. Provides update callbacks to its delegate on the timer, prior to triggering rendering.
  
 */

#import <UIKit/UIKit.h>

@protocol AAPLViewControllerDelegate;

@interface AAPLViewController : UIViewController
@property (nonatomic, weak) IBOutlet id <AAPLViewControllerDelegate> delegate;

// the time interval from the last draw
@property (nonatomic, readonly) NSTimeInterval timeSinceLastDraw;

// What vsync refresh interval to fire at. (Sets CADisplayLink frameinterval property)
// set to 1 by default, which is the CADisplayLink default setting (60 FPS).
// Setting to 2, will cause gameloop to trigger every other vsync (throttling to 30 FPS)
@property (nonatomic) NSUInteger interval;

// Used to pause and resume the controller.
@property (nonatomic, getter=isPaused) BOOL paused;

// used to fire off the main game loop
- (void)dispatchGameLoop;

// use invalidates the main game loop. when the app is set to terminate
- (void)stopGameLoop;

@end

// required view controller delegate functions.
@protocol AAPLViewControllerDelegate <NSObject>
@required

// Note this method is called from the thread the main game loop is run
- (void)update:(AAPLViewController *)controller;

// called whenever the main game loop is paused, such as when the app is backgrounded
- (void)viewController:(AAPLViewController *)controller willPause:(BOOL)pause;
@end
