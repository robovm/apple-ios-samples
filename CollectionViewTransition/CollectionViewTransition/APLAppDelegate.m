/*
     File: APLAppDelegate.m
 Abstract: Template delegate for the application.
  Version: 1.1
 
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

#import "APLAppDelegate.h"
#import "APLTransitionManager.h"
#import "APLStackLayout.h"
#import "APLStackCollectionViewController.h"

@interface APLAppDelegate () <UINavigationControllerDelegate, APLTransitionManagerDelegate>

@property (nonatomic) APLTransitionManager *transitionManager;

@end


#pragma mark -

@implementation APLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    
    // setup our layout and initial collection view
    APLStackLayout *stackLayout = [[APLStackLayout alloc] init];
    APLStackCollectionViewController *collectionViewController = [[APLStackCollectionViewController alloc] initWithCollectionViewLayout:stackLayout];
    collectionViewController.title = @"Stack Layout";
    navController.navigationBar.translucent = NO;
    navController.delegate = self;
    
    // add the single collection view to our navigation controller
    [navController setViewControllers:@[collectionViewController]];
    
    // we want a light gray for the navigation bar, otherwise it defaults to white
    navController.navigationBar.barTintColor = [UIColor lightGrayColor];
    
    // create our "transitioning" object to manage the pinch gesture to transitition between stack and grid layouts
    _transitionManager =
        [[APLTransitionManager alloc] initWithCollectionView:collectionViewController.collectionView];
    self.transitionManager.delegate = self;

    return YES;
}


#pragma mark - APLTransitionControllerDelegate

- (void)interactionBeganAtPoint:(CGPoint)p
{
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    
    // Very basic communication between the transition controller and the top view controller
    // It would be easy to add more control, support pop, push or no-op.
    //
    UIViewController *viewController =
        [(APLCollectionViewController *)navController.topViewController nextViewControllerAtPoint:p];
    if (viewController != nil)
    {
        [navController pushViewController:viewController animated:YES];
    }
    else
    {
        [navController popViewControllerAnimated:YES];
    }
}


#pragma mark - UINavigationControllerDelegate

- (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                          interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController
{
    // return our own transition manager if the incoming controller matches ours
    if (animationController == self.transitionManager)
    {
        return self.transitionManager;
    }
    return nil;
}

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
    id transitionManager = nil;
    
    // make sure we are transitioning from or to a collection view controller, and that interaction is allowed
    if ([fromVC isKindOfClass:[UICollectionViewController class]] &&
        [toVC isKindOfClass:[UICollectionViewController class]] &&
        self.transitionManager.hasActiveInteraction)
    {
        self.transitionManager.navigationOperation = operation;
        transitionManager = self.transitionManager;
    }
    return transitionManager;
}

@end
