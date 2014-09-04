/*
    File:       AppDelegate.m

    Contains:   Main app controller.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "AppDelegate.h"

#import "PhotoGallery.h"

#import "PhotoGalleryViewController.h"

#import "SetupViewController.h"

#import "NetworkManager.h"

#import "Logging.h"

@interface AppDelegate () <SetupViewControllerDelegate>

// private properties

@property (nonatomic, copy,   readwrite) NSString *                     galleryURLString;
@property (nonatomic, retain, readwrite) PhotoGallery *                 photoGallery;
@property (nonatomic, retain, readwrite) PhotoGalleryViewController *   photoGalleryViewController;

// forward declarations

- (void)presentSetupViewControllerAnimated:(BOOL)animated;

@end

@implementation AppDelegate

@synthesize window        = _window;
@synthesize navController = _navController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    #pragma unused(application)
    NSUserDefaults *    userDefaults;
    
    assert(self.window != nil);
    assert(self.navController != nil);
    
    [[QLog log] logWithFormat:@"application start"];
    
    // Tell the PhotoGallery class about application startup, which gives it the 
    // opportunity to do some on-disk garbage collection.
    
    [PhotoGallery applicationStartup];

    // Add an observer to the network manager's networkInUse property so that we can  
    // update the application's networkActivityIndicatorVisible property.  This has 
    // the side effect of starting up the NetworkManager singleton.

    [[NetworkManager sharedManager] addObserver:self forKeyPath:@"networkInUse" options:NSKeyValueObservingOptionInitial context:NULL];

    // If the "applicationClearSetup" user default is set, clear our preferences. 
    // This provides an easy way to get back to the initial state while debugging.
    
    userDefaults = [NSUserDefaults standardUserDefaults];
    if ( [userDefaults boolForKey:@"applicationClearSetup"] ) {
        [userDefaults removeObjectForKey:@"applicationClearSetup"];
        [userDefaults removeObjectForKey:@"galleryURLString"];
        [SetupViewController resetChoices];
    }

    // Get the current gallery URL and, if it's not nil, create a gallery object for it.

    self.galleryURLString = [userDefaults stringForKey:@"galleryURLString"];
    if ( (self.galleryURLString != nil) && ([NSURL URLWithString:self.galleryURLString] == nil) ) {
        // nil is just fine, but a value that doesn't parse as a URL is not.
        self.galleryURLString = nil;
    }
    if (self.galleryURLString != nil) {
        self.photoGallery = [[[PhotoGallery alloc] initWithGalleryURLString:self.galleryURLString] autorelease];
        assert(self.photoGallery != nil);
        
        [self.photoGallery start];
    }
    
    // Set up the main view to display the gallery (if any).  We add our Setup button to the 
    // view controller's navigation items, which seems like a bit of a layer break but it 
    // makes some sort of sense because we want the actions directed to us.
    
    self.photoGalleryViewController = [[[PhotoGalleryViewController alloc] initWithPhotoGallery:self.photoGallery] autorelease];
    assert(self.photoGalleryViewController != nil);

    self.photoGalleryViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Setup" style:UIBarButtonItemStyleBordered target:self action:@selector(setupAction:)] autorelease];
    assert(self.photoGalleryViewController.navigationItem.rightBarButtonItem != nil);
        
    [self.navController pushViewController:self.photoGalleryViewController animated:NO];
    
    [self.window addSubview:self.navController.view];
	[self.window makeKeyAndVisible];

    // If the user hasn't configured the app, push the setup view controller.

    if (self.galleryURLString == nil) {
        [self presentSetupViewControllerAnimated:NO];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
    // When the network manager's networkInUse property changes, update the 
    // application's networkActivityIndicatorVisible property accordingly.
{
    if ([keyPath isEqual:@"networkInUse"]) {
        assert(object == [NetworkManager sharedManager]);
        #pragma unused(change)
        assert(context == NULL);
        assert( [NSThread isMainThread] );
        [UIApplication sharedApplication].networkActivityIndicatorVisible = [NetworkManager sharedManager].networkInUse;
    } else if (NO) {   // Disabled because the super class does nothing useful with it.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
    // When we enter the background make sure to push all of our state 
    // out to disk.
{
    #pragma unused(application)
    [[QLog log] logWithFormat:@"application entered background"];
    if (self.photoGallery != nil) {
        [self.photoGallery save];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application
    // Likewise, on iOS 3, and in exceptional circumstances on iOS 4, 
    // save our state when we are being terminated.
{
    #pragma unused(application)
    [[QLog log] logWithFormat:@"application will terminate"];
    if (self.photoGallery != nil) {
        [self.photoGallery stop];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@synthesize galleryURLString           = _galleryURLString;
@synthesize photoGallery               = _photoGallery;
@synthesize photoGalleryViewController = _photoGalleryViewController;

- (IBAction)setupAction:(id)sender
    // Called when the user taps the Setup button.  It just calls through 
    // to -presentSetupViewControllerAnimated:.
{
    #pragma unused(sender)
    [self presentSetupViewControllerAnimated:YES];
}

- (void)presentSetupViewControllerAnimated:(BOOL)animated
    // Presents the setup view controller.
{
    SetupViewController *   vc;
    
    vc = [[[SetupViewController alloc] initWithGalleryURLString:self.galleryURLString] autorelease];
    assert(vc != nil);
    
    vc.delegate = self;
    
    [vc presentModallyOn:self.navController animated:animated];
}

- (void)setupViewController:(SetupViewController *)controller didChooseString:(NSString *)string
    // A setup view controller delegate callback, called when the user chooses 
    // a gallery URL string.  We respond by reconfiguring the app to display that 
    // gallery.
{
    assert(controller != nil);
    #pragma unused(controller)
    assert(string != nil);
    
    // Disconnect the view controller from the current gallery.

    self.photoGalleryViewController.photoGallery = nil;
    
    // Shut down and dispose of the current gallery.
    
    if (self.photoGallery != nil) {
        [self.photoGallery stop];
        self.photoGallery = nil;
    }

    // Apply the change.
    
    if ( [string length] == 0 ) {
        string = nil;
    }
    self.galleryURLString = string;
    if (self.galleryURLString != nil) {

        // Create a new gallery for the specified URL.
        
        self.photoGallery = [[[PhotoGallery alloc] initWithGalleryURLString:self.galleryURLString] autorelease];
        assert(self.photoGallery != nil);
        
        [self.photoGallery start];
        
        // Point the main view controller at the new gallery.
        
        self.photoGalleryViewController.photoGallery = self.photoGallery;
        
        // Save the user's choice.
        
        [[NSUserDefaults standardUserDefaults] setObject:self.galleryURLString forKey:@"galleryURLString"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"galleryURLString"];
    }
    
    [self.navController dismissModalViewControllerAnimated:YES];
}

- (void)setupViewControllerDidCancel:(SetupViewController *)controller
    // A setup view controller delegate callback, called when the user cancels. 
    // We just dismiss the view controller.
{
    assert(controller != nil);
    #pragma unused(controller)
    [self.navController dismissModalViewControllerAnimated:YES];
}

@end
