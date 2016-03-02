/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Simple LRU (least recently used) cache for Category objects to reduce fetching.
 */

#import <Foundation/Foundation.h>

@class Category;

/*
 About the LRU implementation in this class:
 
 There are many different ways to implement an LRU cache. This class takes a very minimal approach using an integer "access counter". This counter is incremented each time an item is retrieved from the cache, and the item retrieved has a counter that is set to match the counter for the cache as a whole. This is similar to using a timestamp - the access counter for a given cache node indicates at what point it was last used. The counter does not reflect the number of times the node has been used.
 
 With the access counter, it is easy to iterate over the items in the cache and find the item with the lowest access value. This item is the "least recently used" item. 
 */

@interface CategoryCache : NSObject {
    
    NSManagedObjectContext *managedObjectContext;
    // Number of objects that can be cached
    NSUInteger cacheSize;
    // A dictionary holds the actual cached items 
    NSMutableDictionary *cache;
    NSEntityDescription *categoryEntityDescription;
    NSPredicate *categoryNamePredicateTemplate;
    // Counter used to determine the least recently touched item.
    NSUInteger accessCounter;
    // Some basic metrics are tracked to help determine the optimal cache size for the problem.
    CGFloat totalCacheHitCost;
    CGFloat totalCacheMissCost;
    NSUInteger cacheHitCount;
    NSUInteger cacheMissCount;
}

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property NSUInteger cacheSize;
@property (nonatomic, strong) NSMutableDictionary *cache;
@property (nonatomic, strong, readonly) NSEntityDescription *categoryEntityDescription;
@property (nonatomic, strong, readonly) NSPredicate *categoryNamePredicateTemplate;

- (Category *)categoryWithName:(NSString *)name;

@end
