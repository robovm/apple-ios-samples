
/*
     File: APLAppDelegate.m
 Abstract: Application delegate that sets up the root view controller.
 
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

#import "APLAppDelegate.h"
#import "APLViewController.h"

#import "APLRegion.h"


@implementation APLAppDelegate


- (void)applicationDidFinishLaunching:(UIApplication *)application {

	UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
	APLViewController *rootViewController = (APLViewController *)navController.topViewController;

	NSCalendar *calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	rootViewController.calendar = calendar;
	rootViewController.displayList = [self regionsWithCalendar:calendar];
}



- (NSArray *)regionsWithCalendar:(NSCalendar *)calendar {
	/*
	 Create an array of Region objects.
	 Each object represents a geographical region.  Each region contains time zones.
	 Much of the information required to display a time zone is expensive to compute, so rather than using NSTimeZone objects directly use wrapper objects that calculate the required derived values on demand and cache the results.
	 */
	NSArray *knownTimeZoneNames = [NSTimeZone knownTimeZoneNames];

	NSMutableArray *regions = [[NSMutableArray alloc] init];

	for (NSString *timeZoneName in knownTimeZoneNames) {

		NSArray *components = [timeZoneName componentsSeparatedByString:@"/"];
		NSString *regionName = [components objectAtIndex:0];

		APLRegion *region = [APLRegion regionNamed:regionName];
		if (region == nil) {
			region = [APLRegion newRegionWithName:regionName];
			region.calendar = calendar;
			[regions addObject:region];
		}

		NSTimeZone *timeZone = [[NSTimeZone alloc] initWithName:timeZoneName];
		[region addTimeZone:timeZone nameComponents:components];
	}

	// Now sort the time zones by name.
	NSDate *date = [[NSDate alloc] init];
	for (APLRegion *region in regions) {
		[region sortZones];
		[region setDate:date];
	}

    // Sort the regions by name.
	NSArray *sortedRegions = [regions sortedArrayUsingComparator:^(id region1, id region2) {
        NSString *name1 = [(APLRegion *)region1 name];
        NSString *name2 = [(APLRegion *)region2 name];
        // Do comparison
        return [name1 localizedStandardCompare:name2];
    }];

	return sortedRegions;
}

@end
