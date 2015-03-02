/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This is the master view controller that pushes other CloudKitAtlas view controllers onto the view view controller hiearchy.
  
*/

#import "AAPLMasterViewController.h"
#import "AAPLCloudManager.h"

@interface AAPLMasterViewController ()

@property (strong) AAPLCloudManager *cloudManager;

@end

@implementation AAPLMasterViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.cloudManager = [[AAPLCloudManager alloc] init];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id destination = [segue destinationViewController];
    if ([destination respondsToSelector:@selector(setCloudManager:)]) {
        [destination setCloudManager:self.cloudManager];
    }
}

@end
