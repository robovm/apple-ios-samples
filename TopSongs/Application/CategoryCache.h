/*
     File: CategoryCache.h
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
