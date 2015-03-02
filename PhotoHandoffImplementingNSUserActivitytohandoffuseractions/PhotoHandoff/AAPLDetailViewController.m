/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLDetailViewController.h"
#import "AAPLFilterViewController.h"
#import "AAPLDataSource.h"
#import "AAPLImageFilter.h"

@interface AAPLDetailViewController () <UIScrollViewDelegate, AAPLFilterViewControllerDelegate, UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIImage *image;

@property (nonatomic) BOOL filtering;
@property (nonatomic) BOOL needsFilter;
@property (nonatomic, strong) NSMutableDictionary *filters;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintBottom;

@property (nonatomic) CGFloat lastZoomScale;

@property (nonatomic, strong) NSString *currentlyPresentedFilterTitle;

@property (nonatomic, strong) UIActivityViewController *activityViewController;
@property (nonatomic, strong) AAPLFilterViewController *currentFilterViewController;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *blurButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *sepiaButton;

@end


#pragma mark -

@implementation AAPLDetailViewController

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    self.imageView.hidden = YES;
    [self updateImage:NO animate:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    self.imageView.hidden = NO;
    
    [self updateConstraints];
    [self updateZoom];
}

- (void)cleanupFilters {
    
    [self.filters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [obj removeObserver:self forKeyPath:@"dirty"];
    }];
}

- (void)dealloc {
    
    [self cleanupFilters];
}

- (void)updateImage:(BOOL)coalesce animate:(BOOL)animate {
    
    if (self.image == nil) {
        if (self.imageIdentifier) {
            NSString *title = [self.dataSource titleForIdentifier:self.imageIdentifier];
            self.image = [self.dataSource imageForIdentifier:self.imageIdentifier];
            if (animate) {
                self.imageView.alpha = 0.0;
                [UIView animateWithDuration:.5 animations:^{
                    self.title = title;
                    self.imageView.image = self.image;
                    self.imageView.alpha = 1.0;
                }];
            }
            else {
                self.title = title;
                self.imageView.image = self.image;
            }
        }
        else {
            // warning: called without an imageIdentifier set
            return;
        }
    }
    
    if (self.filtering) {
        self.needsFilter = YES;
        return;
    }
    
    if (self.image && self.filters) {
        __block CIImage *filteredCIImage = nil;
        __block CGImageRef cgFilteredImage = NULL;
        BlurFilter *blurFilter = (self.filters)[kBlurFilterKey];
        ModifyFilter *modifyFilter = (self.filters)[kModifyFilterKey];
        BOOL dirty = blurFilter.dirty || modifyFilter.dirty;
        self.filtering = YES;
        
        [self.currentFilterViewController.activityIndicator startAnimating];
        
        void (^runFilters)(void) = ^(void) {
            // blur filter
            if (blurFilter.active && dirty) {
                @try {
                    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
                    if (filter) {
                        [filter setValue:[[CIImage alloc] initWithCGImage:self.image.CGImage] forKey:kCIInputImageKey];
                        [filter setValue:@(blurFilter.blurRadius * 50) forKey:kCIInputRadiusKey];
                        filteredCIImage = [filter valueForKey:kCIOutputImageKey];
                    }
                } @catch (NSException *e) {
                    // Exception trying to set blur filter
                }
            }
            // sepia filter
            if (modifyFilter.active && dirty) {
                @try {
                    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"];
                    if (filter) {
                        [filter setValue:(filteredCIImage ?: [[CIImage alloc] initWithCGImage:self.image.CGImage]) forKey:kCIInputImageKey];
                        [filter setValue:@(modifyFilter.intensity) forKey:kCIInputIntensityKey];
                        filteredCIImage = [filter valueForKey:kCIOutputImageKey];
                    }
                } @catch (NSException *e) {
                    // exception trying to set blur filter
                }
            }
            if (filteredCIImage) {
                CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer: @NO}];
                cgFilteredImage = [context createCGImage:filteredCIImage fromRect:[filteredCIImage extent]];
            }
            
            // block to apply a given filter to be used on the main thread
            void (^applyFilters)(void) = ^(void) {
                if (filteredCIImage) {
                    self.imageView.image = [[UIImage alloc] initWithCGImage:cgFilteredImage];
                }
                else if (dirty) {
                    self.imageView.image = self.image;
                }
                self.filtering = NO;
                
                [self.currentFilterViewController.activityIndicator stopAnimating];
                
                if (self.needsFilter) {
                    self.needsFilter = NO;
                    [self updateImage:YES animate:NO];
                }
                if (cgFilteredImage) {
                    CFRelease(cgFilteredImage);
                }
                [self updateActivity];
                
                [self updateConstraints];
                [self updateZoom];
            };
            if (coalesce) {
                dispatch_async(dispatch_get_main_queue(), applyFilters);
            }
            else {
                applyFilters();
            }
        };
        
        if (coalesce) {
            double delayInSeconds = .25;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), runFilters);
        }
        else {
            runFilters();
        }
        blurFilter.dirty = modifyFilter.dirty = NO;
    }
}

// dismiss any filter view controller and invoke the caller's completion handler then done
- (void)dismissFromActivityWithCompletionHandler:(void (^)(void))completionHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.currentFilterViewController != nil) {
            [self.currentFilterViewController dismissViewControllerAnimated:NO completion:^{
                completionHandler();
            }];
        }
        else {
            completionHandler();
        }
    });
}

#pragma mark - UIScrollViewDelegate

// monitor any zoom scale changes
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    // zooming requires we update our subview constraints
    [self updateConstraints];
}

// indicate which subview in the scroll view is to be zoomed
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    return self.imageView;
}


#pragma mark - AutoLayout

- (void)updateConstraints {
    
    if (self.imageView.image != nil) {
        CGFloat imageWidth = self.imageView.image.size.width;
        CGFloat imageHeight = self.imageView.image.size.height;
        
        CGFloat viewWidth = self.scrollView.bounds.size.width;
        CGFloat viewHeight = self.scrollView.bounds.size.height;
        
        // center image if it is smaller than screen
        CGFloat hPadding = (viewWidth - self.scrollView.zoomScale * imageWidth) / 2;
        if (hPadding < 0)
            hPadding = 0;
        
        float vPadding = (viewHeight - self.scrollView.zoomScale * imageHeight) / 2;
        if (vPadding < 0)
            vPadding = 0;
        
        self.constraintLeft.constant = hPadding;
        self.constraintRight.constant = hPadding;
        
        self.constraintTop.constant = vPadding;
        self.constraintBottom.constant = vPadding;
    }
}

- (void)updateZoom {
    
    // zoom to show as much image as possible unless image is smaller than screen
    CGFloat minZoom = MIN(self.scrollView.bounds.size.width / self.imageView.image.size.width,
                          self.scrollView.bounds.size.height / self.imageView.image.size.height);
    
    if (minZoom > 1)
        minZoom = 1;
    
    self.scrollView.minimumZoomScale = minZoom;
    
    // force scrollViewDidZoom fire if zoom did not change
    if (minZoom == self.lastZoomScale)
        minZoom += 0.000001;
    
    self.lastZoomScale = self.scrollView.zoomScale = minZoom;
}

// Update zoom scale and constraints
// It will also animate because willAnimateRotationToInterfaceOrientation
// is called from within an animation block
//
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    
    [super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
    
    [self updateZoom];
}


#pragma mark - Filtering
// observe when either filter has changed it's value (dirty flag is set, with the blur or sepia values)
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"dirty"]) {
        NSNumber *oldValue = change[NSKeyValueChangeOldKey];
        NSNumber *newValue = change[NSKeyValueChangeNewKey];
        if (([newValue boolValue] == YES) && ([oldValue boolValue] == NO)) {
            [self updateImage:YES animate:NO];
        }
    }
}

// factory method to create either filter by class
+ (AAPLImageFilter *)createImageFilterForKey:(NSString *)key filterClass:(Class)filterClass useDefault:(BOOL)useDefault {
    
    AAPLImageFilter *filter = nil;
    filter = [[filterClass alloc] initFilter:useDefault];
    filter.dirty = NO;
    [UIApplication registerObjectForStateRestoration:filter restorationIdentifier:key];
    filter.objectRestorationClass = [AAPLDetailViewController class];
    return filter;
}

- (AAPLImageFilter *)imageFilterForKey:(NSString *)key class:(Class)filterClass {
    
    if (self.filters == nil) {
        self.filters = [[NSMutableDictionary alloc] init];
    }
    
    AAPLImageFilter *filter = (self.filters)[key];
    if (filter == nil) {
        filter = [AAPLDetailViewController createImageFilterForKey:key filterClass:filterClass useDefault:YES];
        [filter addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        (self.filters)[key] = filter;
    }
    return filter;
}


#pragma mark - Filter View Controllers

#define kBlurButtonTag 1
#define kSepiaButtonTag 2

// as a delegate to UIPopoverPresentationController, we are notified when our
// filterViewController is being dimissed (tapped outside our popover)
//
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    
    UIViewController *testVC = popoverPresentationController.presentedViewController;
    if (testVC == self.currentFilterViewController) {
        self.currentFilterViewController = nil;
    }
}

// as a delegate to FilterViewController, we are notified when our filterViewController is
// being dismissed on its own
//
- (void)wasDismissed {
    
    self.currentFilterViewController = nil;
}

- (void)createAndPresentFilterVC:(id)sender filter:(AAPLImageFilter *)filter identifier:(NSString *)identifier
{
    _currentFilterViewController = [[self storyboard] instantiateViewControllerWithIdentifier:identifier];
    self.currentFilterViewController.filter = filter;
    self.currentFilterViewController.modalPresentationStyle = UIModalPresentationPopover;
    self.currentFilterViewController.popoverPresentationController.barButtonItem = sender;
    self.currentFilterViewController.userActivity = self.userActivity;
    
    // so "wasDismissed" can be called
    self.currentFilterViewController.delegate = self;
    
    // so "popoverPresentationControllerDidDismissPopover" can be called
    self.currentFilterViewController.popoverPresentationController.delegate = self;
    
    [self presentViewController:self.currentFilterViewController animated:YES completion:^{
        [self updateImage:NO animate:NO];
    }];
}
    
- (IBAction)presentFilter:(id)sender {
    
    UIBarButtonItem *button = (UIBarButtonItem *)sender;
    NSString *key = nil;
    Class filterClass = nil;
    NSString *identifier = nil;
    
    if (button.tag == kBlurButtonTag) {
        key = kBlurFilterKey;
        filterClass = [BlurFilter class];
        identifier = @"blurController";
    }
    else if (button.tag == kSepiaButtonTag) {
        key = kModifyFilterKey;
        filterClass = [ModifyFilter class];
        identifier = @"modsController";
    }
    
    if (key != nil) {
        
        self.currentlyPresentedFilterTitle = button.title;
        AAPLImageFilter *filter = [self imageFilterForKey:key class:filterClass];
        
        void (^dismissActivityCompletionHandler) (void) = ^(void) {
            
            self.activityViewController = nil;
            
            // create our presentation filter view controller (but dismiss a previously open filter if necessary)
            void (^dismissCompletionHandler) (void) = ^(void) {
                
                // present a new filter view controller
                [self createAndPresentFilterVC:sender filter:filter identifier:identifier];
            };
            
            if (self.currentFilterViewController != nil) {
                [self.currentFilterViewController dismissViewControllerAnimated:NO completion:dismissCompletionHandler];
            }
            else
            {
                dismissCompletionHandler();
            }
        };
        
        
        // check for activity view controller is open, dismiss it
        if (self.activityViewController != nil) {
            [self.activityViewController dismissViewControllerAnimated:NO completion:dismissActivityCompletionHandler];
        }
        else {
            dismissActivityCompletionHandler();
        }
    }
}

// user tapped "blur" or "sepia" buttons (lower right)
//
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSString *key = nil;
    Class filterClass = Nil;
    NSString *segueIdentifier = [segue identifier];
    
    if ([segueIdentifier isEqualToString:@"showBlurInfo"]) {
        key = kBlurFilterKey;
        filterClass = [BlurFilter class];
    }
    else if ([segueIdentifier isEqualToString:@"showModifyInfo"]) {
        key = kModifyFilterKey;
        filterClass = [ModifyFilter class];
    }
    
    if (key) {
        AAPLImageFilter *filter = [self imageFilterForKey:key class:filterClass];
        AAPLFilterViewController *filterViewController = [segue destinationViewController];
        filterViewController.filter = filter;
    }
}

- (void)cleanupActivity {
    
    self.activityViewController = nil;
    self.activityViewController = nil;
}

- (void)setupActivityCompletion {
    
    __weak AAPLDetailViewController *weakSelf = self;
    self.activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        AAPLDetailViewController *strongSelf = weakSelf;
        [strongSelf cleanupActivity];
    };
}

// user tapped the share button (lower left)
//
- (IBAction)share:(id)sender {
    
    if (self.imageView.image != nil) {
        _activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.imageView.image] applicationActivities:nil];
        self.activityViewController.modalPresentationStyle = UIModalPresentationPopover;
        self.activityViewController.popoverPresentationController.barButtonItem = sender;
        [self setupActivityCompletion];
        self.activityViewController.restorationIdentifier = @"Activity";
        
        void (^dismissCompletionHandler) (void) = ^(void) {
            
            // the filter view controller was dismissed
            self.currentFilterViewController = nil;
            
            // now show our activity view controller
            [self presentViewController:self.activityViewController animated:YES completion:nil];
        };
        
        if (self.currentFilterViewController != nil) {
            [self.currentFilterViewController dismissViewControllerAnimated:NO completion:dismissCompletionHandler];
        }
        else {
            dismissCompletionHandler();
        }
    }
}


#pragma mark - UIStateRestoration

#define kImageIdentifierKey @"kImageIdentifierKey"
#define kDataSourceKey @"kDataSourceKey"
#define kImageFiltersKey @"kImageFiltersKey"
#define kFilterButtonKey @"kFilterButtonKey"
#define kActivityViewControllerKey @"kActivityViewControllerKey"

+ (NSObject<UIStateRestoring>*)objectWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    
    AAPLImageFilter *filter = nil;
    Class filterClass = Nil;
    NSString *key = [identifierComponents lastObject];
    if ([key isEqualToString:kBlurFilterKey]) {
        filterClass = [BlurFilter class];
    }
    else if ([key isEqualToString:kModifyFilterKey]) {
        filterClass = [ModifyFilter class];
    }
    if (filterClass != Nil) {
        filter = [AAPLDetailViewController createImageFilterForKey:key filterClass:filterClass useDefault:NO];
    }
    return filter;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.self.imageIdentifier forKey:kImageIdentifierKey];
    [coder encodeObject:self.dataSource forKey:kDataSourceKey];
    [coder encodeObject:self.filters forKey:kImageFiltersKey];
    
    if (self.currentlyPresentedFilterTitle) {
        [coder encodeObject:self.currentlyPresentedFilterTitle forKey:kFilterButtonKey];
    }
    [coder encodeObject:self.activityViewController forKey:kActivityViewControllerKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super decodeRestorableStateWithCoder:coder];
    
    self.imageIdentifier = [coder decodeObjectForKey:kImageIdentifierKey];
    self.dataSource = [coder decodeObjectForKey:kDataSourceKey];
    self.filters = [coder decodeObjectForKey:kImageFiltersKey];
    
    self.currentlyPresentedFilterTitle = [coder decodeObjectForKey:kFilterButtonKey];
    self.activityViewController = [coder decodeObjectForKey:kActivityViewControllerKey];
    [self setupActivityCompletion];
}

- (void)applicationFinishedRestoringState {
    
    CGSize size = self.view.bounds.size;
    CGPoint imageCenter = self.imageView.center;
    CGPoint center = CGPointMake(size.width / 2, size.height / 2);
    if (!CGPointEqualToPoint(imageCenter, center)) {
        self.imageView.center = center;
        self.imageView.bounds = self.view.bounds;
    }
    [self updateImage:NO animate:NO];
    
    [self.filters enumerateKeysAndObjectsUsingBlock:^(id key, id filter, BOOL *stop) {
        [filter addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    }];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (self.currentlyPresentedFilterTitle) {
            UIBarButtonItem *button = nil;
            if ([self.currentlyPresentedFilterTitle isEqualToString:@"blur"]) {
                button = self.blurButton;
            }
            else if ([self.currentlyPresentedFilterTitle isEqualToString:@"sepia"]) {
                button = self.sepiaButton;
            }
            if (button) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self presentFilter:button];
                });
            }
        }
    }
}


#pragma mark - NSUserActivity

#define kActivityImageBlurKey @"activityImageBlurKey"
#define kActivityImageSepiaKey @"activityImageSepiaKey"

- (void)updateActivity {
    
    if (self.imageIdentifier != nil) {
        self.userActivity.needsSave = YES;
    }
    else {
        // warning - asked to save activity without an imageIdentifier
    }
}

- (void)prepareForActivity {
    
    // handle any kind of work in preparation of the new activity being handed to us
}

- (void)updateUserActivityState:(NSUserActivity *)userActivity {
    
    NSMutableDictionary *userInfoDictionary = [[NSMutableDictionary alloc] init];
    
    // obtain the filter values and save them as part of NSUserActivity
    BlurFilter *blurFilter = (self.filters)[kBlurFilterKey];
    userInfoDictionary[kActivityImageBlurKey] = @(blurFilter.blurRadius);
    
    ModifyFilter *modifyFilter = (self.filters)[kModifyFilterKey];
    userInfoDictionary[kActivityImageSepiaKey] = @(modifyFilter.intensity);
    
    [userActivity addUserInfoEntriesFromDictionary:userInfoDictionary];
}

// we are being asked to restore an activity from another device
- (void)restoreActivityForImageIdentifier:(NSString *)imageIdentifier userInfoDictionary:(NSDictionary *)userInfoDictionary {
    
    if (self.activityViewController != nil) {
        __weak AAPLDetailViewController *weakSelf = self;
        self.activityViewController.completionWithItemsHandler =
        ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            AAPLDetailViewController *strongSelf = weakSelf;
            [strongSelf cleanupActivity];
            [strongSelf restoreActivityForImageIdentifier:imageIdentifier userInfoDictionary:userInfoDictionary];
        };
        return;
    }
    
    self.imageIdentifier = imageIdentifier;
    
    self.image = nil;   // clear the old image
    [self updateImage:NO animate:YES];  // apply the new image (based on imageIdentifier) and apply the 2 filter values
    
    // setup our filters (if not already allocated) and assign their values
    CGFloat blurFilterValue = (CGFloat)[userInfoDictionary[kActivityImageBlurKey] floatValue];
    AAPLImageFilter *blurFilter = [self imageFilterForKey:kBlurFilterKey class:[BlurFilter class]];
    ((BlurFilter *)blurFilter).blurRadius = blurFilterValue;
    if (blurFilterValue > 0) {
        blurFilter.dirty = YES; // the blur has changed from the activity on the other device
    }
    
    CGFloat sepiaFilterValue = (CGFloat)[userInfoDictionary[kActivityImageSepiaKey] floatValue];
    AAPLImageFilter *sepiaFilter = [self imageFilterForKey:kModifyFilterKey class:[ModifyFilter class]];
    ((ModifyFilter *)sepiaFilter).intensity = sepiaFilterValue;
    if (sepiaFilterValue > 0) {
        sepiaFilter.dirty = YES;   // the sepia has changed from the activity on the other device
    }
    
    // providing a different image requires us to adjust our view constraints and zoom
    [self updateConstraints];
    [self updateZoom];
    
    [self updateActivity];  // a different image means updating our current user activity

    // dismiss either filter view controller if necessary
    if (self.currentFilterViewController != nil) {
            [self.currentFilterViewController dismissViewControllerAnimated:NO completion:^{
        }];
    }
    else if (self.activityViewController != nil) {
            [self.activityViewController dismissViewControllerAnimated:NO completion:^{
        }];
    }
}

@end
