/*
     File: AppDelegate.m
 Abstract: Configures the Core Data persistence stack and starts the RSS importer.
  Version: 1.4
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "AppDelegate.h"
#import "SongsViewController.h"

@interface AppDelegate()

@property (nonatomic, strong) SongsViewController *songsViewController;

// Properties for the importer and its background processing queue.
@property (nonatomic, strong) iTunesRSSImporter *importer;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

// Properties for the Core Data stack.
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSString *persistentStorePath;

@end


#pragma mark -

@implementation AppDelegate

// String used to identify the update object in the user defaults storage.
static NSString * const kLastStoreUpdateKey = @"LastStoreUpdate";

// Get the RSS feed for the first time or if the store is older than kRefreshTimeInterval seconds.
static NSTimeInterval const kRefreshTimeInterval = 3600;

// The number of songs to be retrieved from the RSS feed.
static NSUInteger const kImportSize = 300;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
    // check the last update, stored in NSUserDefaults
    NSDate *lastUpdate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastStoreUpdateKey];
    if (lastUpdate == nil || -[lastUpdate timeIntervalSinceNow] > kRefreshTimeInterval) {
        
        // remove the old store; easier than deleting every object
        // first, test for an existing store
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.persistentStorePath]) {
            NSError *error = nil;
            BOOL oldStoreRemovalSuccess = [[NSFileManager defaultManager] removeItemAtPath:self.persistentStorePath error:&error];
            NSAssert3(oldStoreRemovalSuccess, @"Unhandled error adding persistent store in %s at line %d: %@", __FUNCTION__, __LINE__, [error localizedDescription]);
        }
        
        // create an importer object to retrieve, parse, and import into the CoreData store 
        self.importer = [[iTunesRSSImporter alloc] init];
        self.importer.delegate = self;
        // pass the coordinator so the importer can create its own managed object context
        self.importer.persistentStoreCoordinator = self.persistentStoreCoordinator;
        self.importer.iTunesURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wpa/MRSS/newreleases/limit=%d/rss.xml", kImportSize]];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        // add the importer to an operation queue for background processing (works on a separate thread)
        [self.operationQueue addOperation:self.importer];
    }

    // obtain our current initial view controller on the nav stack and set it's managed object context
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    _songsViewController = (SongsViewController *)navController.visibleViewController;
    self.songsViewController.managedObjectContext = self.managedObjectContext;
}

- (NSOperationQueue *)operationQueue {
    
    if (_operationQueue == nil) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return _operationQueue;
}


#pragma mark - Core Data stack setup

//
// These methods are very slightly modified from what is provided by the Xcode template
// An overview of what these methods do can be found in the section "The Core Data Stack" 
// in the following article: 
// http://developer.apple.com/iphone/library/documentation/DataManagement/Conceptual/iPhoneCoreData01/Articles/01_StartingOut.html
//

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (_persistentStoreCoordinator == nil) {
        NSURL *storeUrl = [NSURL fileURLWithPath:self.persistentStorePath];
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[NSManagedObjectModel mergedModelFromBundles:nil]];
        NSError *error = nil;
        NSPersistentStore *persistentStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error];
        NSAssert3(persistentStore != nil, @"Unhandled error adding persistent store in %s at line %d: %@", __FUNCTION__, __LINE__, [error localizedDescription]);
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    
    if (_managedObjectContext == nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [self.managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    }
    return _managedObjectContext;
}

- (NSString *)persistentStorePath {
    
    if (_persistentStorePath == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths lastObject];
        _persistentStorePath = [documentsDirectory stringByAppendingPathComponent:@"TopSongs.sqlite"];
    }
    return _persistentStorePath;
}


#pragma mark - <iTunesRSSImporterDelegate> Implementation

// This method will be called on a secondary thread. Forward to the main thread for safe handling of UIKit objects.
- (void)importerDidSave:(NSNotification *)saveNotification {
    
    if ([NSThread isMainThread]) {
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:saveNotification];
        [self.songsViewController fetch];
    } else {
        [self performSelectorOnMainThread:@selector(importerDidSave:) withObject:saveNotification waitUntilDone:NO];
    }
}

// Helper method for main-thread processing of import completion.
- (void)handleImportCompletion {
    
    // Store the current time as the time of the last import. This will be used to determine whether an
    // import is necessary when the application runs.
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastStoreUpdateKey];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.importer = nil;
}

// This method will be called on a secondary thread. Forward to the main thread for safe handling of UIKit objects.
- (void)importerDidFinishParsingData:(iTunesRSSImporter *)importer {
    
    [self performSelectorOnMainThread:@selector(handleImportCompletion) withObject:nil waitUntilDone:NO];
}

// Helper method for main-thread processing of errors received in the delegate callback below.
- (void)handleImportError:(NSError *)error {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.importer = nil;
    
    // handle errors as appropriate to your application, here we just alert the user
    //
    NSString *errorMessage = [error localizedDescription];
    NSString *alertTitle = NSLocalizedString(@"Error", @"Title for alert displayed when download or parse error occurs.");
    NSString *okTitle = NSLocalizedString(@"OK ", @"OK Title for alert displayed when download or parse error occurs.");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                        message:errorMessage
                                                       delegate:nil
                                              cancelButtonTitle:okTitle
                                              otherButtonTitles:nil];
    [alertView show];
}

// This method will be called on a secondary thread. Forward to the main thread for safe handling of UIKit objects.
- (void)importer:(iTunesRSSImporter *)importer didFailWithError:(NSError *)error {
    
    [self performSelectorOnMainThread:@selector(handleImportError:) withObject:error waitUntilDone:NO];
}

@end

