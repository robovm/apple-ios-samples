/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This view controller lets you subscribe and unsubscribe to items.
  
*/

#import "AAPLCKSubscriptionViewController.h"
#import "AAPLCloudManager.h"

@interface AAPLCKSubscriptionViewController()

@property (weak) IBOutlet UISwitch *subscriptionSwitch;

- (void) subscriptionPreferenceUpdated:(id)sender;

@end

@implementation AAPLCKSubscriptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.subscriptionSwitch.on = self.cloudManager.subscribed;
}

- (IBAction)subscriptionPreferenceUpdated:(UISwitch *)sender {
    if (sender.on) {
        // Turn on subscription
        [self.cloudManager subscribe];
    } else {
        // Turn off subscription
        [self.cloudManager unsubscribe];
    }
}

@end
