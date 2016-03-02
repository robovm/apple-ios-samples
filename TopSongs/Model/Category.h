/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Managed object subclass for Category entity.
 */

#import <Foundation/Foundation.h>

@interface Category : NSManagedObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSSet *songs;

@end
