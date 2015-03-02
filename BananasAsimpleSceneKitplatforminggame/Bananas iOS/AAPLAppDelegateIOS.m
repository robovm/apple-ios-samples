/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The iOS-specific implementation of the application delegate. See AAPLAppDelegate for implementation shared between platforms. Uses NSProgress to display a loading UI while the app loads its assets.
  
 */

#import "AAPLAppDelegateIOS.h"
#import "AAPLSceneView.h"
#import "AAPLViewController.h"

@implementation AAPLAppDelegateIOS {
	UIProgressView *_progressView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	if ([keyPath isEqualToString:@"fractionCompleted"]) {
		double fraction = ((NSProgress *)object).fractionCompleted;
		dispatch_async(dispatch_get_main_queue(), ^{
			_progressView.progress = fraction;
		});
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	AAPLViewController *rootViewController = [[AAPLViewController alloc] init];
	application.statusBarHidden = YES;
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.window.backgroundColor = [UIColor purpleColor];
	self.window.rootViewController = rootViewController;
	self.scnView = rootViewController.sceneView;

	[self.window makeKeyAndVisible];


	_progressView = [[UIProgressView alloc] initWithFrame:CGRectInset(self.scnView.bounds, 40, 40)];
	[self.scnView addSubview:_progressView];
	NSProgress *prepareProgress = [NSProgress progressWithTotalUnitCount:1];
	[prepareProgress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:NULL];
	[prepareProgress becomeCurrentWithPendingUnitCount:1];

	[self commonApplicationDidFinishLaunchingWithCompletionHandler:^{

		[prepareProgress removeObserver:self forKeyPath:@"fractionCompleted"];
		[_progressView removeFromSuperview];
		_progressView = nil;
	}];
	[prepareProgress resignCurrent];

	return YES;
}

@end
