/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A category on NSIndexPath for getting an index path of an object within an array, in section 0.
 */
@import Foundation;

@interface NSIndexPath (ArrayIndex)

/**
 *  Looks up the index of that object in the provided array, then uses it to build an indexPath in section 0.
 *
 *  @param object The object to look up.
 *  @param array  The array in which to look up the object.
 *
 *  @return An indexPath with section 0 if the object was found in the array, or nil if the object was not in the array.
 */
+ (instancetype)hmc_indexPathOfObject:(id)object inArray:(NSArray *)array;

@end
