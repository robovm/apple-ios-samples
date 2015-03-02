/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLAppDelegate.h"
#import "AAPLDataSource.h"
#import "AAPLViewController.h"

@interface AAPLAppDelegate ()
@property (nonatomic, readwrite) AAPLDataSource *dataSource;
@end


#pragma mark -

@implementation AAPLAppDelegate

// easy access to our primary collection view controller
- (AAPLViewController *)primaryViewController
{
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    return (navigationController.viewControllers)[0];
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // setup and restore our data source of images
    self.dataSource = [[AAPLDataSource alloc] init];
    [UIApplication registerObjectForStateRestoration:self.dataSource restorationIdentifier:@"DataSource"];
    
    // hand off the data source to our primary collection view controller
    AAPLViewController *primaryViewController = [self primaryViewController];
    primaryViewController.dataSource = self.dataSource;
     
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // any app setup done here after state restoration has occurred
    //
    return YES;
}


#pragma mark - NSUserActivity

- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType {
    
    AAPLViewController *primaryViewController = [self primaryViewController];
    primaryViewController.dataSource = self.dataSource;
    
    //NSLog(@"%s: Preparing for activity with type %@, viewController is %@", __PRETTY_FUNCTION__, userActivityType, primaryViewController);
    
    [primaryViewController prepareForActivity];
    return YES;
}

// Called on the main thread after the NSUserActivity object is available.
// Use the data you stored in the NSUserActivity object to re-create what the user was doing.
// You can create/fetch any restorable objects associated with the user activity, and pass them to the restorationHandler.
//
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    AAPLViewController *viewController = (AAPLViewController *)(navigationController.viewControllers)[0];
    
    //NSLog(@"%s: Handling activity %@, viewController is %@", __PRETTY_FUNCTION__, userActivity, viewController);
    
    [viewController handleUserActivity:userActivity];
    restorationHandler(@[navigationController, viewController]);
    
    return YES;
}

// If the user activity cannot be fetched after willContinueUserActivityWithType is called,
// this will be called on the main thread when implemented.
//
- (void)application:(UIApplication *)application didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error {
    
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    AAPLViewController *viewController = (AAPLViewController *)(navigationController.viewControllers)[0];
    
    //NSLog(@"%s: Failed to continue activity type: %@", __PRETTY_FUNCTION__, userActivityType);
    
    // tell our  view controller to handle failure to get activity
    [viewController handleActivityFailure];
}

// This is called on the main thread when a user activity managed by UIKit has been updated.
// You can use this as a last chance to add additional data to the userActivity.
//
- (void)application:(UIApplication *)application didUpdateUserActivity:(NSUserActivity *)userActivity {
    
    //NSLog(@"%s: Did update user activity: %@", __PRETTY_FUNCTION__, userActivity);
}


#pragma mark - UIStateRestoration

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    return YES;
}

@end
