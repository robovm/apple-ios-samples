/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Discoverability lets you request for the user's First Name and Last Name from their iCloud account
 */

#import "AAPLDiscoverabilityViewController.h"
#import "AAPLCloudManager.h"

@interface AAPLDiscoverabilityViewController()

@property (weak) IBOutlet UILabel *name;

@end

@implementation AAPLDiscoverabilityViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.cloudManager requestDiscoverabilityPermission:^(BOOL discoverable) {
        
        if (discoverable) {
            [self.cloudManager discoverUserInfo:^(CKDiscoveredUserInfo *user) {
                [self discoveredUserInfo:user];
            }];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"CloudKit Catalog" message:@"Getting your name using Discoverability requires permission." preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
                [self dismissViewControllerAnimated:YES completion:nil];
                
            }];
            
            [alert addAction:action];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)discoveredUserInfo:(CKDiscoveredUserInfo *)user {
    if (user) {
        NSString *fullName = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];

        self.name.text = fullName;
    } else {
        self.name.text = @"Anonymous";
    }
}

@end
