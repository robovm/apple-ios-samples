/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates applying a custom background to a navigation bar.
 */

#import "CustomAppearanceViewController.h"
#import "NavigationController.h"

@interface CustomAppearanceViewController ()
@property (nonatomic, weak) IBOutlet UISegmentedControl *backgroundSwitcher;
//! An array of city names, populated from Cities.json.
@property (nonatomic, strong) NSArray *cities;
@end


@implementation CustomAppearanceViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load some data to populate the table view with
    NSURL *citiesJSONURL = [[NSBundle mainBundle] URLForResource:@"Cities" withExtension:@"json"];
    NSData *citiesJSONData = [NSData dataWithContentsOfURL:citiesJSONURL];
    self.cities = [NSJSONSerialization JSONObjectWithData:citiesJSONData options:0 error:NULL];
    
    // Place the background switcher in the toolbar.
    UIBarButtonItem *backgroundSwitcherItem = [[UIBarButtonItem alloc] initWithCustomView:self.backgroundSwitcher];
    [self setToolbarItems:@[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
        backgroundSwitcherItem,
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL]
    ]];
    
    [self applyImageBackgroundToTheNavigationBar];
}


//| ----------------------------------------------------------------------------
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // This works around a bug in iOS 8.0 - 8.2 in which the navigation bar
    // will not display the correct background image after rotating the device.
    // This bug affects bars in navigation controllers that are presented
    // modally. A bar in the window's rootViewController would not be affected.
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // The workaround is to toggle some appearance related setting on the
        // navigation bar when we detect that the view controller has changed
        // interface orientations.  In our example, we call the
        // -configureNewNavBarBackground: which reapplies our appearance
        // based on the current selection.  In a real app, changing just the
        // barTintColor or barStyle would have the same effect.
        [self configureNewNavBarBackground:self.backgroundSwitcher];
    } completion:NULL];
}


//| ----------------------------------------------------------------------------
//! Configures the navigation bar to use an image as its background.
//
- (void)applyImageBackgroundToTheNavigationBar
{
    // These background images contain a small pattern which is displayed
    // in the lower right corner of the navigation bar.
    UIImage *backgroundImageForDefaultBarMetrics = [UIImage imageNamed:@"NavigationBarDefault"];
    UIImage *backgroundImageForLandscapePhoneBarMetrics = [UIImage imageNamed:@"NavigationBarLandscapePhone"];
    
    // Both of the above images are smaller than the navigation bar's
    // size.  To enable the images to resize gracefully while keeping their
    // content pinned to the bottom right corner of the bar, the images are
    // converted into resizable images width edge insets extending from the
    // bottom up to the second row of pixels from the top, and from the
    // right over to the second column of pixels from the left.  This results
    // in the topmost and leftmost pixels being stretched when the images
    // are resized.  Not coincidentally, the pixels in these rows/columns
    // are empty.
    backgroundImageForDefaultBarMetrics = [backgroundImageForDefaultBarMetrics resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, backgroundImageForDefaultBarMetrics.size.height - 1, backgroundImageForDefaultBarMetrics.size.width - 1)];
    backgroundImageForLandscapePhoneBarMetrics = [backgroundImageForLandscapePhoneBarMetrics resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, backgroundImageForLandscapePhoneBarMetrics.size.height - 1, backgroundImageForLandscapePhoneBarMetrics.size.width - 1)];
    
    // You should use the appearance proxy to customize the appearance of
    // UIKit elements.  However changes made to an element's appearance
    // proxy do not effect any existing instances of that element currently
    // in the view hierarchy.  Normally this is not an issue because you
    // will likely be performing your appearance customizations in
    // -application:didFinishLaunchingWithOptions:.  However, this example
    // allows you to toggle between appearances at runtime which necessitates
    // applying appearance customizations directly to the navigation bar.
    /* id navigationBarAppearance = [UINavigationBar appearanceWhenContainedIn:[NavigationController class], nil]; */
    id navigationBarAppearance = self.navigationController.navigationBar;
    
    // The bar metrics associated with a background image determine when it
    // is used.  The background image associated with the Default bar metrics
    // is used when a more suitable background image can not be found.
    [navigationBarAppearance setBackgroundImage:backgroundImageForDefaultBarMetrics forBarMetrics:UIBarMetricsDefault];
    // The background image associated with the LandscapePhone bar metrics
    // is used by the shorter variant of the navigation bar that is used on
    // iPhone when in landscape.
    [navigationBarAppearance setBackgroundImage:backgroundImageForLandscapePhoneBarMetrics forBarMetrics:UIBarMetricsCompact];
}


//| ----------------------------------------------------------------------------
//! Configures the navigation bar to use a transparent background (see-through
//! but without any blur).
//
- (void)applyTransparentBackgroundToTheNavigationBar:(CGFloat)opacity
{
    UIImage *transparentBackground;
    
    // The background of a navigation bar switches from being translucent
    // to transparent when a background image is applied.  The intensity of
    // the background image's alpha channel is inversely related to the
    // transparency of the bar.  That is, a smaller alpha channel intensity
    // results in a more transparent bar and vis-versa.
    //
    // Below, a background image is dynamically generated with the desired
    // opacity.
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, self.navigationController.navigationBar.layer.contentsScale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 1, 1, 1, opacity);
    UIRectFill(CGRectMake(0, 0, 1, 1));
    transparentBackground = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // You should use the appearance proxy to customize the appearance of
    // UIKit elements.  However changes made to an element's appearance
    // proxy do not effect any existing instances of that element currently
    // in the view hierarchy.  Normally this is not an issue because you
    // will likely be performing your appearance customizations in
    // -application:didFinishLaunchingWithOptions:.  However, this example
    // allows you to toggle between appearances at runtime which necessitates
    // applying appearance customizations directly to the navigation bar.
    /* id navigationBarAppearance = [UINavigationBar appearanceWhenContainedIn:[NavigationController class], nil]; */
    id navigationBarAppearance = self.navigationController.navigationBar;
    
    [navigationBarAppearance setBackgroundImage:transparentBackground forBarMetrics:UIBarMetricsDefault];
}

//| ----------------------------------------------------------------------------
//! Configures the navigation bar to use a custom color as its background.
//! The navigation bar remains translucent.
//
- (void)applyBarTintColorToTheNavigationBar
{
    // Be aware when selecting a barTintColor for a translucent bar that
    // the tint color will be blended with the content passing under
    // the translucent bar.  See QA1808 for more information.
    // <https://developer.apple.com/library/ios/qa/qa1808/_index.html>
    UIColor *barTintColor = [UIColor colorWithRed:176/255.0f green:226/255.0f blue:172/255.0f alpha:1.0f];
    UIColor *darkendBarTintColor = [UIColor colorWithRed:(176/255.0f - .05f) green:(226/255.0f - .02f) blue:(172/255.0f - .05f) alpha:1.0f];
    
    // You should use the appearance proxy to customize the appearance of
    // UIKit elements.  However changes made to an element's appearance
    // proxy do not effect any existing instances of that element currently
    // in the view hierarchy.  Normally this is not an issue because you
    // will likely be performing your appearance customizations in
    // -application:didFinishLaunchingWithOptions:.  However, this example
    // allows you to toggle between appearances at runtime which necessitates
    // applying appearance customizations directly to the navigation bar.
    /* id navigationBarAppearance = [UINavigationBar appearanceWhenContainedIn:[NavigationController class], nil]; */
    id navigationBarAppearance = self.navigationController.navigationBar;

    [navigationBarAppearance setBarTintColor:darkendBarTintColor];
    
    // For comparison, apply the same barTintColor to the toolbar, which
    // has been configured to be opaque.
    [self.navigationController.toolbar setBarTintColor:barTintColor];
    self.navigationController.toolbar.translucent = NO;
}

#pragma mark -
#pragma mark Background Switcher

//| ----------------------------------------------------------------------------
- (IBAction)configureNewNavBarBackground:(UISegmentedControl*)sender
{
    // Reset everything.
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsCompact];
    [self.navigationController.navigationBar setBarTintColor:nil];
    [self.navigationController.toolbar setBarTintColor:nil];
    self.navigationController.toolbar.translucent = YES;
    
    switch (sender.selectedSegmentIndex) {
        case 0: /* Transparent Background */ {
            [self applyImageBackgroundToTheNavigationBar];
            break;
        }
        case 1: /* Transpaent */ {
            [self applyTransparentBackgroundToTheNavigationBar:0.87];
            break;
        }
        case 2: /* Color */ {
            [self applyBarTintColorToTheNavigationBar];
            break;
        }
        default:
            break;
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

//| ----------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cities.count;
}


//| ----------------------------------------------------------------------------
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = self.cities[indexPath.row];
    
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

//| ----------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.navigationItem.prompt isEqualToString:self.cities[indexPath.row]]) {
        self.navigationItem.prompt = nil;
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else
        self.navigationItem.prompt = self.cities[indexPath.row];
}

@end
