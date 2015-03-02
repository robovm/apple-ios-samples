/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The OS X-specific implementation of the application delegate. See AAPLAppDelegate for implementation shared between platforms.
  
 */

#import "AAPLAppDelegateOSX.h"

@implementation AAPLAppDelegateOSX

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[self window] disableSnapshotRestoration];

	[self commonApplicationDidFinishLaunchingWithCompletionHandler:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

- (IBAction)pause:(id)sender
{
	[self togglePaused];
}

@end
