
/*
     File: APLRegion.m
 Abstract: Object to represent a region containing the corresponding time zone wrappers.
 
  Version: 3.0
 
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

#import "APLRegion.h"
#import "APLTimeZoneWrapper.h"


static NSMutableDictionary *regions;

@interface APLRegion ()
@property (nonatomic) NSMutableArray *mutableTimeZoneWrappers;
@end


@implementation APLRegion

/*
 Class methods to manage global regions (pun intended).
 */
+ (void)initialize {
	regions = [[NSMutableDictionary alloc] init];	
}


+ (instancetype)regionNamed:(NSString *)name {
	return regions[name];
}


+ (instancetype)newRegionWithName:(NSString *)regionName {
    // Create a new region with a given name; add it to the regions dictionary.
	APLRegion *newRegion = [[self alloc] init];
	newRegion.name = regionName;
	newRegion.mutableTimeZoneWrappers = [[NSMutableArray alloc] init];
	regions[regionName] = newRegion;
	return newRegion;
}


-(NSArray *)timeZoneWrappers {
    return _mutableTimeZoneWrappers;
}


- (void)addTimeZone:(NSTimeZone *)timeZone nameComponents:(NSArray *)nameComponents {
    // Add a time zone to the region; use nameComponents because it' expensive to compute.
	APLTimeZoneWrapper *timeZoneWrapper = [[APLTimeZoneWrapper alloc] initWithTimeZone:timeZone nameComponents:nameComponents];
	timeZoneWrapper.calendar = self.calendar;
	[self.mutableTimeZoneWrappers addObject:timeZoneWrapper];
}


- (void)sortZones {
    // Sort the zone wrappers by locale name.
    NSSortDescriptor *nameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"localeName" ascending:YES comparator:^(id name1, id name2) {
        return [(NSString *)name1 localizedStandardCompare:(NSString *)name2];
    }];
    
	[self.mutableTimeZoneWrappers sortUsingDescriptors:@[nameSortDescriptor]];
}


// Sets the date for the time zones, which has the side-effect of "faulting" the wrappers (see APLTimeZoneWrapper's setDate: method)
- (void)setDate:(NSDate *)date {
	for (APLTimeZoneWrapper *wrapper in self.timeZoneWrappers) {
		wrapper.date = date;
	}
}


@end
