/*
     File: AppDelegate.m
 Abstract: Main app controller.
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

#import "NetworkManager.h"

@interface AppDelegate () <UIApplicationDelegate>

// things for IB

@property (nonatomic, strong, readwrite) IBOutlet UITabBarController * tabs;

@end

@implementation AppDelegate
{
    char                _networkOperationCountDummy;
}

@synthesize window      = _window;

+ (void)initialize
    // Set up our default preferences.  We can't do this in -applicationDidFinishLaunching: 
    // because it's too late; the view controller's -viewDidLoad method has already run 
    // by the time applicationDidFinishLaunching: is called.
{
    if ([self class] == [AppDelegate class]) {
        NSString *      initialDefaultsPath;
        NSDictionary *  initialDefaults;
    
        initialDefaultsPath = [[NSBundle mainBundle] pathForResource:@"InitialDefaults" ofType:@"plist"];
        assert(initialDefaultsPath != nil);
        
        initialDefaults = [NSDictionary dictionaryWithContentsOfFile:initialDefaultsPath];
        assert(initialDefaults != nil);
        
        // If we're running on the device certain defaults don't make any sense 
        // (specifically, the upload defaults, which reference localhost), so 
        // we nix them.
        
        #if ! TARGET_IPHONE_SIMULATOR
        {
            NSMutableDictionary *   initialDefaultsChanged;
            
            initialDefaultsChanged = [initialDefaults mutableCopy];
            assert(initialDefaultsChanged != nil);
            
            [initialDefaultsChanged setObject:@"" forKey:@"CreateDirURLText"];
            [initialDefaultsChanged setObject:@"" forKey:@"PutURLText"];
            
            initialDefaults = initialDefaultsChanged;
        }
        #endif
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:initialDefaults];
    }
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    #pragma unused(application)
    assert(self.window != nil);
    assert(self.tabs != nil);
    
    [[NetworkManager sharedInstance] addObserver:self forKeyPath:@"networkOperationCount" options:NSKeyValueObservingOptionInitial context:&self->_networkOperationCountDummy];
    
    self.tabs.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"currentTab"];
    [self.window makeKeyAndVisible];
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    assert(tabBarController == self.tabs);
    #pragma unused(tabBarController)
    #pragma unused(viewController)
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger) self.tabs.selectedIndex forKey:@"currentTab"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->_networkOperationCountDummy) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = ([NetworkManager sharedInstance].networkOperationCount != 0);
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
