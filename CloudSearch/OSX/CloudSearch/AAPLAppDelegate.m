/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This this sample's application delegate.
 */

#import "AAPLAppDelegate.h"
#import "AAPLWindowController.h"

#pragma mark -

@interface AAPLAppDelegate ()

@property (nonatomic, strong) id ubiquityToken;
@property (nonatomic, strong) NSURL *ubiquityContainer;
@property (nonatomic, strong) IBOutlet AAPLWindowController *myWindowController;
@property (nonatomic, strong) NSArray *documents;

@end


#pragma mark -

@implementation AAPLAppDelegate

// -------------------------------------------------------------------------------
//	applicationShouldTerminateAfterLastWindowClosed:sender
//
//	NSApplication delegate method placed here so the sample conveniently quits
//	after we close the window.
// -------------------------------------------------------------------------------
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

// -------------------------------------------------------------------------------
//  setupWindowContent
// -------------------------------------------------------------------------------
- (void)setupWindowContent
{
    // clear out the old documents in the window
    [self.myWindowController clearDocuments];
    
    AAPLCloudDocumentsController *docsController = [AAPLCloudDocumentsController sharedInstance];
    
    for (NSInteger idx = 0; idx < [docsController numberOfDocuments]; idx++)
    {
        // get the file name and URL
        NSURL *itemURL = [docsController urlForDocumentAtIndex:idx];
        NSString *itemName = [docsController titleForDocumentAtIndex:idx];
        
        // get the file modification date
        NSDate *modDate = [docsController modDateForDocumentAtIndex:idx];
        
        NSImage *icon = [docsController iconForDocumentAtIndex:idx];
        
        // add this document to the Manage window
        [self.myWindowController addDocument:itemURL
                                    withName:itemName
                            modificationDate:modDate
                                        icon:icon];
    }
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
        NSURL *documentsCloudDirectoryURL = [self ubiquityDocumentsFolder];
        
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
        
        // create the Documents folder in iCloud in case one doesn't exist
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
//  applicationDidFinishLaunching:notification
// -------------------------------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)notification
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
            
            AAPLCloudDocumentsController *docsController = [AAPLCloudDocumentsController sharedInstance];
            docsController.fileType = @"txt";   // start by finding only 'txt' files
            docsController.delegate = self;     // we need to be notified when cloud docs are found
            
            if (![docsController startScanning])
            {
                // present an error to say that it wasn't possible to start the iCloud query
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Search_Failed", nil)
                                                                     forKey:NSLocalizedDescriptionKey];
                NSError *error = [[NSError alloc] initWithDomain:@"Application" code:200 userInfo:userInfo];
                [NSApp presentError:error];
            }
        });
    });
    
    // listen for when the current ubiquity identity has changed (user logs in and out of iCloud)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ubiquityIdentityChanged:)
                                                 name:NSUbiquityIdentityDidChangeNotification
                                               object:nil];
    
    [[self.myWindowController window] makeKeyAndOrderFront:self];
}

//----------------------------------------------------------------------------------------
// ubiquityIdentityChanged
//
// Notification that the user has either logged in our out of iCloud.
//----------------------------------------------------------------------------------------
- (void)ubiquityIdentityChanged:(NSNotification *)note
{
    id token = [[NSFileManager defaultManager] ubiquityIdentityToken];
    if (token == nil)
    {
        NSAlert *warningAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Logged_Out_Message", nil)
                                                defaultButton:NSLocalizedString(@"OK_Button_Title", nil)
                                              alternateButton:nil
                                                  otherButton:nil
                                    informativeTextWithFormat:NSLocalizedString(@"Logged_Out_Message_Explain", nil)];
        warningAlert.alertStyle = NSWarningAlertStyle;
        [warningAlert runModal];
        
        // we are logged out so clear our window and stop the Spotlight search
        [[AAPLCloudDocumentsController sharedInstance] stopScanning];
        [self.myWindowController clearDocuments];
    }
    else
    {
        if ([self.ubiquityToken isEqual:token])
        {
            NSLog(@"user has stayed logged in with same account");
        }
        else
        {
            // user logged in with a different account
            NSLog(@"user logged in with a new account");
        }
        
        // store off this token to compare later
        self.ubiquityToken = token;
        
        // startup our Spotlight search again
        [[AAPLCloudDocumentsController sharedInstance] restartScan];
    }
}

// -------------------------------------------------------------------------------
//  applicationDidBecomeActive:notification
// -------------------------------------------------------------------------------
- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    _ubiquityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
}

// -------------------------------------------------------------------------------
//  applicationWillTerminate
// -------------------------------------------------------------------------------
- (void)applicationWillTerminate:(NSNotification *)notification
{
    // remove the default documents we copied to the cloud
    [self removeDocumentsFromCloud];
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSUbiquityIdentityDidChangeNotification
                                                  object:nil];
}


#pragma mark - CloudDocumentsControllerDelegate

// -------------------------------------------------------------------------------
//	didRetrieveCloudDocuments
// -------------------------------------------------------------------------------
- (void)didRetrieveCloudDocuments
{
    [self setupWindowContent];
    
    // we have stopped looking for documents, stop progress animation
    [self.myWindowController.progIndicator stopAnimation:self];
}

// -------------------------------------------------------------------------------
//	didRetrieveCloudDocuments
// -------------------------------------------------------------------------------
- (void)didStartRetrievingCloudDocuments
{
    // we are looking for documents, show progress animation
    [self.myWindowController.progIndicator startAnimation:self];
}

@end
