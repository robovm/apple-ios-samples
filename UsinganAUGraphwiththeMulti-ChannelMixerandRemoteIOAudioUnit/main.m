/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The application main.
*/

#import <UIKit/UIKit.h>
#import "MultichannelMixerTestDelegate.h"

int main(int argc, char *argv[])
{
    int retVal = 0;
    @autoreleasepool {
        retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([MultichannelMixerTestDelegate class]));
    }
    return retVal;
}