/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The OS X-specific implementation of the application delegate. See AAPLAppDelegate for implementation shared between platforms.
  
 */

#import "AAPLAppDelegate.h"
#import <Cocoa/Cocoa.h>

@interface AAPLAppDelegateOSX : AAPLAppDelegate <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@end
