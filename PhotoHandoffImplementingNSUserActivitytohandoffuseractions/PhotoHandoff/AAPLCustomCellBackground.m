/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLCustomCellBackground.h"

@implementation AAPLCustomCellBackground

+ (UIView *)customCellBackground {
    
    id obj = [[self class] alloc];
    return obj;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.backgroundColor = [UIColor lightGrayColor];
        self.layer.cornerRadius = 5.0;
    }
    return self;
}

@end
