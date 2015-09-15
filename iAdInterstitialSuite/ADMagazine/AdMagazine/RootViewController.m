/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The primary view controller containing the page view controller.
 */

#import "RootViewController.h"
#import "ModelController.h"
#import "DataViewController.h"

@interface RootViewController ()

@property (nonatomic, strong) ModelController *modelController;
@property (nonatomic, strong) IBOutlet UIView *pageViewControllerPlaceHolder;
@property (nonatomic, strong) UIPageViewController *pageViewController;

@end


#pragma mark -

@implementation RootViewController

@synthesize modelController = _modelController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pageViewController =
        [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl
                                        navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                      options:nil];
    self.pageViewController.delegate = self;

    DataViewController *startingViewController = [self.modelController viewControllerAtIndex:0 storyboard:self.storyboard];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];

    self.pageViewController.dataSource = self.modelController;

    // add the page view controller as a child to this view controller
    [self addChildViewController:self.pageViewController];
    [self.pageViewControllerPlaceHolder addSubview:self.pageViewController.view];
    self.pageViewController.view.frame = self.pageViewControllerPlaceHolder.bounds;
    [self.pageViewController didMoveToParentViewController:self];

    // Add the page view controller's gesture recognizers to the book view controller's
    // view so that the gestures are started more easily.
    //
    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
}

- (ModelController *)modelController
{
    // Return the model controller object, creating it if necessary.
    if (!_modelController)
    {
        _modelController = [[ModelController alloc] init];
    }
    return _modelController;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


#pragma mark - UIPageViewControllerDelegate

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        // In portrait orientation: Set the spine position to "min" and the page view controller's view
        // controllers array to contain just one view controller. Setting the spine position to
        // 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to YES,
        // so set it to NO here.
        //
        UIViewController *currentViewController = self.pageViewController.viewControllers[0];
        NSArray *viewControllers = @[currentViewController];
        [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
        
        self.pageViewController.doubleSided = NO;
        return UIPageViewControllerSpineLocationMin;
    }

    // In landscape orientation: Set set the spine location to "mid" and the page view controller's
    // view controllers array to contain two view controllers. If the current page is even, set it to
    // contain the current and next view controllers; if it is odd, set the array to contain the previous
    // and current view controllers.
    //
    DataViewController *currentViewController = self.pageViewController.viewControllers[0];
    NSArray *viewControllers = nil;

    NSUInteger indexOfCurrentViewController = [self.modelController indexOfViewController:currentViewController];
    if (indexOfCurrentViewController == 0 || indexOfCurrentViewController % 2 == 0)
    {
        UIViewController *nextViewController = [self.modelController pageViewController:self.pageViewController viewControllerAfterViewController:currentViewController];
        viewControllers = @[currentViewController, nextViewController];
    }
    else
    {
        UIViewController *previousViewController = [self.modelController pageViewController:self.pageViewController viewControllerBeforeViewController:currentViewController];
        viewControllers = @[previousViewController, currentViewController];
    }
    [self.pageViewController setViewControllers:viewControllers
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:YES
                                     completion:nil];

    return UIPageViewControllerSpineLocationMid;
}

@end
