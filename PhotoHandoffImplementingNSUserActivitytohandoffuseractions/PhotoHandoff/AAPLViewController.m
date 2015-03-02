/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLViewController.h"
#import "AAPLDetailViewController.h"
#import "AAPLDataSource.h"
#import "AAPLCell.h"

NSString *kDetailedViewControllerID = @"DetailView";    // view controller storyboard id
NSString *kCellID = @"cellID";                          // UICollectionViewCell id
NSString *kDetailSegueName = @"showDetail";             // segue ID to navigate to the detail view controller

@interface AAPLViewController () <NSUserActivityDelegate>
@property (nonatomic, strong) AAPLDetailViewController *detailViewController;
@end


#pragma mark -

@implementation AAPLViewController

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    NSArray *selectedItems = [self.collectionView indexPathsForSelectedItems];
    if ([selectedItems count]) {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             [self.collectionView deselectItemAtIndexPath:selectedItems[0] animated:YES];
                         }
                         completion:nil];
    }
    
    // if we are popping back from a detail view controller, clear any activity
    if (self.detailViewController) {
        if (self.userActivity) {
            //NSLog(@"%s: Clearing user activity property", __PRETTY_FUNCTION__);
            self.userActivity = nil;
        }
        self.detailViewController = nil;
    }
}


#pragma mark - NSUserActivity

- (void)updateUserActivityState:(NSUserActivity *)userActivity {
    
    NSString *imageIdentifier = self.detailViewController.imageIdentifier;
    if (imageIdentifier) {
        userActivity.title = [self.dataSource titleForIdentifier:imageIdentifier];
        [userActivity addUserInfoEntriesFromDictionary:@{ @"imageIdentifier" : imageIdentifier }];
        
        //NSLog(@"%s: Updated activity with title %@, imageIdentifier is string %@, userInfo dictionary is %@", __PRETTY_FUNCTION__, userActivity.title, imageIdentifier, userActivity.userInfo);
    }
}

- (void)restoreUserActivityState:(NSUserActivity *)userActivity {
    
    //NSLog(@"%s: Called with user activity %@ with title %@, userInfo %@", __PRETTY_FUNCTION__, userActivity, userActivity.title, userActivity.userInfo);
}

// the user activity was continued on another device
- (void)userActivityWasContinued:(NSUserActivity *)userActivity
{
    /*// we no longer are interested in our detail view controller since it was handed off to the other device
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.navigationController popViewControllerAnimated:YES];
    });*/
    
    // we no longer are interested in our detail view controller since it was handed off to the other device
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.detailViewController != nil)
        {
            void (^dismissActivityCompletionHandler) (void) = ^(void) {
                
                [self.navigationController popViewControllerAnimated:YES];
            };
            
            // dismiss any filter view controller and invoke our completion handler then done
            [self.detailViewController dismissFromActivityWithCompletionHandler:dismissActivityCompletionHandler];
        }
    });
}

- (void)saveActivity:(NSString *)imageIdentifier {
    
    NSUserActivity *userActivity = self.userActivity;
    if (userActivity == nil) {
        //NSLog(@"%s: Creating user activity", __PRETTY_FUNCTION__);
        userActivity = [[NSUserActivity alloc] initWithActivityType:[[NSBundle mainBundle] bundleIdentifier]];
        userActivity.delegate = self;   // so we can be notified when another device takes over an activity
    }
    userActivity.needsSave = YES;
    self.userActivity = userActivity;
    self.detailViewController.userActivity = userActivity;

    if (self.presentedViewController) {
        // so coming back to foreground will make activity current when something is presented
        self.presentedViewController.userActivity = userActivity;
    }
}

- (void)instantiateAndPushDetailViewController:(BOOL)animated {
    
    // we use our bundle identifier to define the user activity
    self.detailViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"AAPLDetailViewController"];
    self.detailViewController.dataSource = self.dataSource;
    [self.navigationController pushViewController:self.detailViewController animated:NO];
}

- (BOOL)handleActivityUserInfo:(NSDictionary *)userInfoDictionary {
    
    NSString *imageIdentifier = userInfoDictionary[@"imageIdentifier"];
    if (imageIdentifier == nil) {
        //NSLog(@"%s: User Activity doesn't have an imageIdentifier", __PRETTY_FUNCTION__);
        [self handleActivityFailure];
        return NO;
    }
    //NSLog(@"%s: User Activity has imageIdentifier is %@", __PRETTY_FUNCTION__, imageIdentifier);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[imageIdentifier integerValue] inSection:0];
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    if (self.detailViewController == nil) {
        //NSLog(@"%s: FYI: No detailViewController exists for activity, creating and pushing a detail view controller...", __PRETTY_FUNCTION__);
        [self instantiateAndPushDetailViewController:YES];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.detailViewController restoreActivityForImageIdentifier:imageIdentifier userInfoDictionary:userInfoDictionary];
        [self saveActivity:imageIdentifier];
    });
    
    return YES;
}

- (BOOL)handleUserActivity:(NSUserActivity *)userActivity {
    
    BOOL rc = NO;
    NSDictionary *userInfoDictionary = userActivity.userInfo;
    rc = [self handleActivityUserInfo:userInfoDictionary];
    [self clearActivityContinuationInProgress];
    return rc;
}

- (void)clearActivityContinuationInProgress {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)prepareForActivity {
    
    if (self.detailViewController == nil) {
        [self instantiateAndPushDetailViewController:YES];
    }
    else {
        [self.detailViewController prepareForActivity];
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)handleActivityFailure {
    
    // pop the current view controller since something failed
    if (self.detailViewController != nil && self.detailViewController.imageIdentifier == nil) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    [self clearActivityContinuationInProgress];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    
    return [self.dataSource numberOfItemsInSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    AAPLCell *cell = [cv dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
 
    NSString *imageIdentifier = [self.dataSource identifierForIndexPath:indexPath];
    NSString *text = [self.dataSource titleForIdentifier:imageIdentifier];
    cell.label.text = text;
    cell.image.image = [self.dataSource thumbnailForIdentifier:imageIdentifier];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:kDetailSegueName]) {
        NSIndexPath *selectedIndexPath = [self.collectionView indexPathsForSelectedItems][0];
        NSString *imageIdentifier = [self.dataSource identifierForIndexPath:selectedIndexPath];
        self.detailViewController = [segue destinationViewController];
        self.detailViewController.imageIdentifier = imageIdentifier;
        self.detailViewController.dataSource = self.dataSource;
        [self saveActivity:imageIdentifier];    // create our new NSUserActivity handled us
        [self clearActivityContinuationInProgress];
    }
}


#pragma mark - UIStateRestoration

#define kDetailViewControllerKey @"kDetailViewControllerKey"

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super encodeRestorableStateWithCoder:coder];
    if (self.detailViewController) {
        [coder encodeObject:self.detailViewController forKey:kDetailViewControllerKey];
    }
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super decodeRestorableStateWithCoder:coder];
    self.detailViewController = [coder decodeObjectForKey:kDetailViewControllerKey];
}

- (void)applicationFinishedRestoringState {
    
    if (self.detailViewController.imageIdentifier) {
        [self saveActivity:self.detailViewController.imageIdentifier];
    }
}

@end










