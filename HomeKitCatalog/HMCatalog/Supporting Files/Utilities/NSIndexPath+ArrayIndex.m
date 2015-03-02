/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A category on NSIndexPath for getting an index path of an object within an array, in section 0.
 */

@import UIKit.UITableView;
#import "NSIndexPath+ArrayIndex.h"

@implementation NSIndexPath (ArrayIndex)

+ (instancetype)hmc_indexPathOfObject:(id)object inArray:(NSArray *)array {
    NSUInteger index = [array indexOfObject:object];
    if (index == NSNotFound)
        return nil;
    return [self indexPathForRow:index inSection:0];
}

@end
