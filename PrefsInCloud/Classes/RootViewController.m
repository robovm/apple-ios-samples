/*
     File: RootViewController.m
 Abstract: The main view controller for this app, showing the preferred background color.
  Version: 1.2
 
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

#import "RootViewController.h"

typedef enum ColorIndex:uint32_t
{   // it is a good idea to give your enums a specific bit size.
    kColorWhite = 0,
    kColorRed,
    kColorGreen,
    kColorYellow,
} ColorIndex;

bool IsValidColorIndex(long long colorIndex)
{
    return kColorWhite <= colorIndex <= kColorYellow;
}

void AssertValidColorIndex(ColorIndex colorIndex)
{
    NSCAssert(IsValidColorIndex(colorIndex), @"Invalid Color Index %d", colorIndex);
}


#pragma mark -

@interface RootViewController() <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UIView *frontView;
@property (nonatomic, strong) IBOutlet UIView *backView;

@property (nonatomic, strong) NSArray *priorConstraints;

@end


#pragma mark -

@implementation RootViewController

#pragma mark - ColorIndex Conversion Methods

// convert a ColorIndex into a UIColor that can be used for a background
- (UIColor *)backgroundColorFromColorIndex:(ColorIndex)colorIndex
{
    AssertValidColorIndex(colorIndex);
    switch (colorIndex)
    {
        case kColorWhite:  return [UIColor whiteColor];
        case kColorRed:    return [UIColor redColor];
        case kColorGreen:  return [UIColor greenColor];
        case kColorYellow: return [UIColor yellowColor];
    }
    return nil;
}

// the display name for a color index
- (NSString *)colorNameFromColorIndex:(ColorIndex)colorIndex
{
    AssertValidColorIndex(colorIndex);
    switch (colorIndex)
    {
        case kColorWhite:  return NSLocalizedString(@"White",@"");
        case kColorRed:    return NSLocalizedString(@"Red",@"");
        case kColorGreen:  return NSLocalizedString(@"Green",@"");
        case kColorYellow: return NSLocalizedString(@"Yellow",@"");
    }
    
    return NSLocalizedString(@"Unknown Color",@"");
}

- (NSIndexPath*)indexPathForColorIndex:(ColorIndex)ci
{
    AssertValidColorIndex(ci);
    return [NSIndexPath indexPathForRow:ci inSection:0];
}

- (ColorIndex)colorIndexAtIndexPath:(NSIndexPath*)path;
{
    ColorIndex ci = path.row;
    AssertValidColorIndex(ci);
    return ci;
}


#pragma mark - Color Saving

// The key-value store is not a replacement for NSUserDefaults or other local techniques
// for saving the same data. The purpose of the key-value store is to share data between apps,
// but if iCloud is not enabled or is not available on a given device, you still might want
// to keep a local copy of the data.
//
// For more information, see the "Preferences and Settings Programming Guide: Storing Preferences in iCloud":
//  <http://developer.apple.com/library/ios/documentation/cocoa/Conceptual/UserDefaults/StoringPreferenceDatainiCloud/StoringPreferenceDatainiCloud.html#//apple_ref/doc/uid/10000059i-CH7-SW7>
//
// It is important to keep your NSUserDefaults and NSUbiquitousKeyValueStore values in sync.
// It helps to only update them from a method that updates them both.


// preference key for storing our background color (used both for NSUserDefaults and KVStore)
static NSString *kBackgroundColorKey = @"backgroundColor";

// We always read the chosen color from local NSUserDefaults.
// NSUbiquitousKeyValueStore is used to update NSUserDefaults.
// Default is kColorWhite (0) if no color has been chosen yet.
//
- (NSInteger) chosenColorIndex;
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBackgroundColorKey];
}

// update the chosen color
- (void) setChosenColorIndex:(ColorIndex)newColorIndex;
{
    AssertValidColorIndex(newColorIndex); //it is a programming error to attempt to save an invalid value.
    
    NSUbiquitousKeyValueStore *kvStore = [NSUbiquitousKeyValueStore defaultStore];
    [kvStore setLongLong:newColorIndex forKey:kBackgroundColorKey];
    
    [[NSUserDefaults standardUserDefaults] setInteger:newColorIndex forKey:kBackgroundColorKey];
    
    // update the UI
    [self updateFrontViewColor];
}


#pragma mark - View Methods

- (void)updateFrontViewColor;
{
    UIColor *chosenColor = [self backgroundColorFromColorIndex:self.chosenColorIndex];
    self.frontView.backgroundColor = chosenColor;
}

- (UIBarButtonItem *)doneButton
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                         target:self
                                                         action:@selector(flipAction:)];
}

- (UIBarButtonItem *)flipButton
{
	UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self action:@selector(flipAction:) forControlEvents:UIControlEventTouchUpInside];
    return [[UIBarButtonItem alloc] initWithCustomView:infoButton];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // listen for key-value store changes to our preference value, externally from the cloud
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateCloudItems:)
                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object:store];
        // note: by passing "object", it tells the cloud that we want to use "key-value store"
        // (which will allow other devices to automatically sync)

    self.frontView.frame = self.view.bounds;
    self.backView.frame = self.view.bounds;
    
    [self.view addSubview:self.frontView]; // start out showing the front view
    
    // add our custom 'i' flip button as the nav bar's custom right view
    self.navigationItem.rightBarButtonItem = [self flipButton];
	   
    // make sure we're showing the latest color.
    [self updateFrontViewColor];
    
    // Get any KVStore change since last launch,
    // This will spark the notification "NSUbiquitousKeyValueStoreDidChangeExternallyNotification",
    // to any interested party within this app who is listening for iCloud KVStore changes.
    //
    // It is important to only do this step *after* registering for notifications,
    // this prevents a notification arriving before code is ready to respond to it.
    //
    [store synchronize];
}

- (void)dealloc
{
    // Even though we are using ARC, we still need to manually stop observing any
    // NSNotificationCenter notifications.  Otherwise we could get "zombie" crashes when
    // NSNotificationCenter tries to notify us after our -dealloc finished.
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                  object:[NSUbiquitousKeyValueStore defaultStore]];
}


#pragma mark - Actions

// makes "subview" match the width and height of "superview" by adding the proper auto layout constraints
//
- (NSArray *)constrainSubview:(UIView *)subview toMatchWithSuperview:(UIView *)superview
{
    subview.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(subview);
    
    NSArray *constraints = [NSLayoutConstraint
                            constraintsWithVisualFormat:@"H:|[subview]|"
                            options:0
                            metrics:nil
                            views:viewsDictionary];
    constraints = [constraints arrayByAddingObjectsFromArray:
                   [NSLayoutConstraint
                    constraintsWithVisualFormat:@"V:|[subview]|"
                    options:0
                    metrics:nil
                    views:viewsDictionary]];
    [superview addConstraints:constraints];
    
    return constraints;
}

// called when the user presses the 'i' icon to change the app settings
//
- (void)flipAction:(id)sender
{
	BOOL goingToFrontView = (self.backView.superview != nil);

    UIView *fromView = goingToFrontView ? self.backView : self.frontView;
    UIView *toView = goingToFrontView ? self.frontView : self.backView;
    
    toView.frame = fromView.frame;
    
    UIViewAnimationOptions transitionDirection = goingToFrontView ? UIViewAnimationOptionTransitionFlipFromRight : UIViewAnimationOptionTransitionFlipFromLeft;
    UIBarButtonItem *finalRightBarButtonItem = goingToFrontView ? [self flipButton] : [self doneButton];
    
    NSArray *priorConstraints = self.priorConstraints;
    [UIView transitionFromView:fromView
                        toView:toView
                      duration:1.0
                       options:transitionDirection
                    completion:^(BOOL finished) {
                        // animation completed, adjust our done/info buttons accordingly
                        [self.navigationItem setRightBarButtonItem:finalRightBarButtonItem animated:YES];
                        
                        if (priorConstraints != nil)
                        {
                            [self.view removeConstraints:priorConstraints];
                        }
                    }];
    _priorConstraints = [self constrainSubview:toView toMatchWithSuperview:self.view];
}


#pragma mark - UITableViewDelegate

const NSInteger kNumberOfColorRows = 4;

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // clean out the old checkmark state
    for (NSInteger row = 0; row < kNumberOfColorRows; row++)
    {
        NSIndexPath *rowIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [tableView cellForRowAtIndexPath:rowIndexPath].accessoryType = UITableViewCellAccessoryNone;
    }
    
    // apply the new checkmark state
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ColorIndex chosenColor = [self colorIndexAtIndexPath:indexPath];
    [self setChosenColorIndex:chosenColor];
}


#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Background Colors:",@"");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return kNumberOfColorRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kOneCellID = @"cellID";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kOneCellID];
	if (cell == nil){
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kOneCellID];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
	
    NSIndexPath *chosenIndex = [self indexPathForColorIndex:[self chosenColorIndex]];
	// checkmark the selected cell
    if ([indexPath isEqual:chosenIndex])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
	cell.textLabel.text = [self colorNameFromColorIndex:indexPath.row];
    
	return cell;
}


#pragma mark - Cloud support

// This method is called when the key-value store in the cloud has changed externally.
// The old color value is replaced with the new one. Additionally, NSUserDefaults is updated as well.
//
- (void)updateCloudItems:(NSNotification *)notification
{
	// We get more information from the notification, by using:
    // NSUbiquitousKeyValueStoreChangeReasonKey or NSUbiquitousKeyValueStoreChangedKeysKey constants
    // against the notification's useInfo.
	//
    NSDictionary *userInfo = [notification userInfo];
    
    // get the reason for the notification (initial download, external change or quota violation change)
    NSInteger reason = [[userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey] integerValue];
    
    // reason can be:
    //
    // NSUbiquitousKeyValueStoreServerChange:
    //      Value(s) were changed externally from other users/devices.
    //      Get the changes and update the corresponding keys locally.
    // 
    // NSUbiquitousKeyValueStoreInitialSyncChange:
    //      Initial downloads happen the first time a device is connected to an iCloud account,
    //      and when a user switches their primary iCloud account.
    //      Get the changes and update the corresponding keys locally.
    //
    // note: if you receive "NSUbiquitousKeyValueStoreInitialSyncChange" as the reason,
    // you can decide to "merge" your local values with the server values
    //
    if (reason == NSUbiquitousKeyValueStoreInitialSyncChange)
    {
        // do the merge
        // ... but for this sample we have only one value, so a merge is not necessary
    }
    
    NSArray *changedKeys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
    
    // check if any of the keys we care about were updated, and if so use the new value stored under that key.
    for (NSString *changedKey in changedKeys)
    {
        if ([changedKey isEqualToString:kBackgroundColorKey])
        {
            // Replace our "selectedColor" with the value from the cloud, but *only* if it's a value we know how to interpret.
            // It is important to validate any value that comes in through iCloud, because it could have been generated by a different version of your app.
            long long possibleColorIndexFromiCloud = [[NSUbiquitousKeyValueStore defaultStore] longLongForKey:kBackgroundColorKey];
            if (IsValidColorIndex(possibleColorIndexFromiCloud))
            {
                // we know the new value is valid, use it.
                [self setChosenColorIndex:(ColorIndex)possibleColorIndexFromiCloud];
            }
            else
            {
                // the value isn't something we can understand.
                // The best way to handle an unexpected value depends on what the value represents, and what your app does.
                // But a good rule of thumb is to ignore values you can not interpret and not apply the update.
                //
                NSLog(@"WARNING: Invalid kBackgroundColorKey value of %lld received from iCloud. This value will be ignored.", possibleColorIndexFromiCloud);
            }
        }
    }
}

@end
