/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Application Delegate
*/

#import <UIKit/UIKit.h>

#import "MyViewController.h"
#import "CAXException.h"

@interface MultichannelMixerTestDelegate : NSObject <UIApplicationDelegate> {
    IBOutlet UIWindow *window;
    
    IBOutlet UINavigationController	*navigationController;
	IBOutlet MyViewController		*myViewController;
}

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet MyViewController *myViewController;

@end

