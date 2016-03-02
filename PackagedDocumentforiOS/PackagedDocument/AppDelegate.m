/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UIApplication delegate for the application.
 */

#import "AppDelegate.h"

@implementation AppDelegate

// The app delegate must implement the window @property
// from UIApplicationDelegate @protocol to use a main storyboard file.
@synthesize window;

+ (NSURL *)localDocumentsDirectoryURL
{
    // returns the directory in which documents are stored
    static NSURL *localDocumentsDirectoryURL = nil;
    
    if (localDocumentsDirectoryURL == nil)
    {
        NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        localDocumentsDirectoryURL = [NSURL fileURLWithPath:documentsDirectoryPath];
    }
    return localDocumentsDirectoryURL;
}

@end