/*
     File: CategoryCache.m
 Abstract: Simple LRU (least recently used) cache for Category objects to reduce fetching.
  Version: 1.4
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "CategoryCache.h"
#import "Category.h"

// CacheNode is a simple object to help with tracking cached items
//
@interface CacheNode : NSObject {
    NSManagedObjectID *objectID;
    NSUInteger accessCounter;
}

@property (nonatomic, strong) NSManagedObjectID *objectID;
@property NSUInteger accessCounter;

@end


#pragma mark -

@implementation CacheNode

@synthesize objectID, accessCounter;

@end


#pragma mark -

@implementation CategoryCache

@synthesize managedObjectContext, cacheSize, cache;

- (id)init {
    
    self = [super init];
    if (self != nil) {
        cacheSize = 15;
        accessCounter = 0;
        cache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (cacheHitCount > 0) NSLog(@"average cache hit cost:  %f", totalCacheHitCost/cacheHitCount);
    if (cacheMissCount > 0) NSLog(@"average cache miss cost: %f", totalCacheMissCost/cacheMissCount);
    categoryEntityDescription = nil;
    categoryNamePredicateTemplate = nil;
}

// Implement the "set" accessor rather than depending on @synthesize so that we can set up registration
// for context save notifications.
- (void)setManagedObjectContext:(NSManagedObjectContext *)aContext {
    
    if (managedObjectContext) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
    }
    managedObjectContext = aContext;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
}

// When a managed object is first created, it has a temporary managed object ID. When the managed object context in which it was created is saved, the temporary ID is replaced with a permanent ID. The temporary IDs can no longer be used to retrieve valid managed objects. The cache handles the save notification by iterating through its cache nodes and removing any nodes with temporary IDs.
// While it is possible force Core Data to provide a permanent ID before an object is saved, using the method -[ NSManagedObjectContext obtainPermanentIDsForObjects:error:], this method incurrs a trip to the database, resulting in degraded performance - the very thing we are trying to avoid. 
- (void)managedObjectContextDidSave:(NSNotification *)notification {
    
    CacheNode *cacheNode = nil;
    NSMutableArray *keys = [NSMutableArray array];
    for (NSString *key in cache) {
        cacheNode = [cache objectForKey:key];
        if ([cacheNode.objectID isTemporaryID]) {
            [keys addObject:key];
        }
    }
    [cache removeObjectsForKeys:keys];
}

- (NSEntityDescription *)categoryEntityDescription {
    
    if (categoryEntityDescription == nil) {
        categoryEntityDescription = [NSEntityDescription entityForName:@"Category" inManagedObjectContext:managedObjectContext];
    }
    return categoryEntityDescription;
}

static NSString * const kCategoryNameSubstitutionVariable = @"NAME";

- (NSPredicate *)categoryNamePredicateTemplate {
    
    if (categoryNamePredicateTemplate == nil) {
        NSExpression *leftHand = [NSExpression expressionForKeyPath:@"name"];
        NSExpression *rightHand = [NSExpression expressionForVariable:kCategoryNameSubstitutionVariable];
        categoryNamePredicateTemplate = [[NSComparisonPredicate alloc] initWithLeftExpression:leftHand rightExpression:rightHand modifier:NSDirectPredicateModifier type:NSLikePredicateOperatorType options:0];   
    }
    return categoryNamePredicateTemplate;
}

// Undefine this macro to compare performance without caching
#define USE_CACHING

- (Category *)categoryWithName:(NSString *)name {
    
    NSTimeInterval before = [NSDate timeIntervalSinceReferenceDate];
#ifdef USE_CACHING
    // check cache
    CacheNode *cacheNode = [cache objectForKey:name];
    if (cacheNode != nil) {
        // cache hit, update access counter
        cacheNode.accessCounter = accessCounter++;
        Category *category = (Category *)[managedObjectContext objectWithID:cacheNode.objectID];
        totalCacheHitCost += ([NSDate timeIntervalSinceReferenceDate] - before);
        cacheHitCount++;
        return category;
    }
#endif
    // cache missed, fetch from store - if not found in store there is no category object for the name and we must create one
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:self.categoryEntityDescription];
    NSPredicate *predicate = [self.categoryNamePredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:name forKey:kCategoryNameSubstitutionVariable]];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    NSArray *fetchResults = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSAssert1(fetchResults != nil, @"Unhandled error executing fetch request in import thread: %@", [error localizedDescription]);

    Category *category = nil;
    if ([fetchResults count] > 0) {
        // get category from fetch
        category = [fetchResults objectAtIndex:0];
    } else if ([fetchResults count] == 0) {
        // category not in store, must create a new category object 
        category = [[Category alloc] initWithEntity:self.categoryEntityDescription insertIntoManagedObjectContext:managedObjectContext];
        category.name = name;
    }
#ifdef USE_CACHING
    // add to cache
    // first check to see if cache is full
    if ([cache count] >= cacheSize) {
        // evict least recently used (LRU) item from cache
        NSUInteger oldestAccessCount = UINT_MAX;
        NSString *key = nil, *keyOfOldestCacheNode = nil;
        for (key in cache) {
            CacheNode *tmpNode = [cache objectForKey:key];
            if (tmpNode.accessCounter < oldestAccessCount) {
                oldestAccessCount = tmpNode.accessCounter;
                keyOfOldestCacheNode = key;
            }
        }
        // retain the cache node for reuse
        cacheNode = [cache objectForKey:keyOfOldestCacheNode];
        // remove from the cache
        if (keyOfOldestCacheNode != nil)
            [cache removeObjectForKey:keyOfOldestCacheNode];
    } else {
        // create a new cache node
        cacheNode = [[CacheNode alloc] init];
    }
    cacheNode.objectID = [category objectID];
    cacheNode.accessCounter = accessCounter++;
    [cache setObject:cacheNode forKey:name];
#endif
    totalCacheMissCost += ([NSDate timeIntervalSinceReferenceDate] - before);
    cacheMissCount++;
    return category;
}

@end
