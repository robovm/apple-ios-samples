/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The application delegate class used for installing our navigation controller.
 */

#import "AAPLAppDelegate.h"

@interface AAPLAppDelegate ()

@property (nonatomic, strong) id ubiquityToken;
@property (nonatomic, strong) NSURL *ubiquityContainer;
@property (nonatomic, strong) NSArray *documents;

@end

#pragma mark -

@implementation AAPLAppDelegate

// The app delegate must implement the window @property
// from UIApplicationDelegate @protocol to use a main storyboard file.
@synthesize window;

// -------------------------------------------------------------------------------
//  didFinishLaunchingWithOptions:launchOptions
// -------------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // do this asynchronously since if this is the first time this particular device
    // is syncing with preexisting iCloud content it may take a long time to download
    //
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // remember our ubiquity container NSURL for later use
        _ubiquityContainer = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        
        // back on the main thread, setup the cloud documents controller which queries
        // the cloud and manages our list of cloud documents:
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            
            _documents = @[@"Text Document1.txt",
                           @"Text Document2.txt",
                           @"Text Document3.txt",
                           @"Image Document.jpg",
                           @"PDF Document.pdf",
                           @"HTML Document.html"];
            [self copyDefaultDocumentsToCloud];
        });
    });
    
    return YES;
}

// -------------------------------------------------------------------------------
//  ubiquityDocumentsFolder
// -------------------------------------------------------------------------------
- (NSURL *)ubiquityDocumentsFolder
{
    return [self.ubiquityContainer URLByAppendingPathComponent:@"Documents" isDirectory:YES];
}

// -------------------------------------------------------------------------------
//  copyDefaultDocumentsToCloud
//
//  Copy the default documents to the cloud, done each time we launch the app.
// -------------------------------------------------------------------------------
- (void)copyDefaultDocumentsToCloud
{
    // copy the built-in documents to the cloud
    if (self.ubiquityContainer != nil)
    {
        NSURL *documentsCloudDirectoryURL = self.ubiquityDocumentsFolder;
        
        // create the Documents folder in iCloud in case one doesn't exist
        [[NSFileManager defaultManager] createDirectoryAtURL:documentsCloudDirectoryURL
                                 withIntermediateDirectories:NO
                                                  attributes:nil
                                                       error:nil];

        for (NSString *documentName in self.documents)
        {
            NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:documentName];
            NSString *destPath = [[documentsCloudDirectoryURL path] stringByAppendingPathComponent:documentName];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:destPath])
            {
                // document doesn't exist in the cloud yet, so copy it
                [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:destPath error:nil];
            }
        }
    }
}

// -------------------------------------------------------------------------------
//  removeDocumentsFromCloud
//
//  Remove the default documents we copied to the cloud, done when the app quits.
// -------------------------------------------------------------------------------
- (void)removeDocumentsFromCloud
{
    if (self.ubiquityContainer != nil)
    {
        NSURL *documentsCloudDirectoryURL = [self ubiquityDocumentsFolder];

        for (NSString *documentName in self.documents)
        {
            NSString *removePath = [[documentsCloudDirectoryURL path] stringByAppendingPathComponent:documentName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:removePath])
            {
                [[NSFileManager defaultManager] removeItemAtPath:removePath error:nil];
            }
        }
    }
}

// -------------------------------------------------------------------------------
//  applicationWillTerminate
// -------------------------------------------------------------------------------
- (void)applicationWillTerminate:(UIApplication *)application;
{
    // remove the default documents we copied to the cloud
    [self removeDocumentsFromCloud];
}

@end
