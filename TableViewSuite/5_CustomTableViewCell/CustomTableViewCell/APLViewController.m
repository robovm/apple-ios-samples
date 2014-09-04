
/*
     File: APLViewController.m
 Abstract: View controller that sets up the table view and the time zone data.
 
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

#import "APLViewController.h"

@interface APLViewController ()

@property (nonatomic, weak) NSTimer *minuteTimer;
@property (nonatomic, weak) NSTimer *regionsTimer;

@end


#import "APLViewController.h"
#import "APLTimeZoneCell.h"
#import "APLTimeZoneWrapper.h"
#import "APLRegion.h"

#import "APLAppDelegate.h"

@implementation APLViewController

#pragma mark - Table view datasource and delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	// Number of sections is the number of regions
	return [self.displayList count];
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	// Number of rows is the number of time zones in the region for the specified section
	APLRegion *region = [self.displayList objectAtIndex:section];
	NSArray *regionTimeZones = region.timeZoneWrappers;
	return [regionTimeZones count];
}


- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	// Section title is the region name
	APLRegion *region = [self.displayList objectAtIndex:section];
	return region.name;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {

	static NSString *CellIdentifier = @"TimeZoneCell";

	APLTimeZoneCell *timeZoneCell = (APLTimeZoneCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	// Get the time zones for the region for the section
	APLRegion *region = [self.displayList objectAtIndex:indexPath.section];
	NSArray *regionTimeZones = region.timeZoneWrappers;

	// Get the time zone wrapper for the row
	[timeZoneCell setTimeZoneWrapper:[regionTimeZones objectAtIndex:indexPath.row]];
	return timeZoneCell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	/*
	 To illustrate the effect of highlighting the cell, don't set the selection style to None in the storyboard, instead implement this method to immediately deselect the cell.
	 */
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {

	/*
	 Set up two timers, one that fires every minute, the other every fifteen minutes.

	 1/ The time displayed for each time zone must be updated every minute on the minute.
	 2/ Time zone data is cached. Some time zones are based on 15 minute differences from GMT, so update the cache every 15 minutes, on the "quarter".
     */

	NSTimer *timer;
    NSDate *date = [NSDate date];

    /*
	 Set up a timer to update the table view every minute on the minute so that it shows the current time.
	 */
    NSDate *oneMinuteFromNow = [date dateByAddingTimeInterval:60];

    NSCalendarUnit unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;

    NSCalendar *calendar = self.calendar;

    NSDateComponents *timerDateComponents = [calendar components:unitFlags fromDate:oneMinuteFromNow];
	// Add 1 second to make sure the minute update has passed when the timer fires.
	[timerDateComponents setSecond:1];
	NSDate *minuteTimerDate = [calendar dateFromComponents:timerDateComponents];

	timer = [[NSTimer alloc] initWithFireDate:minuteTimerDate interval:60 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	self.minuteTimer = timer;

	/*
	 Set up a timer to update the region data every 15 minutes on the quarter, so that the regions show the current date.
	 */
    NSInteger minutesToNextQuarter = 15 - ([timerDateComponents minute] % 15);
    NSDateComponents *minutesToNextQuarterComponents = [[NSDateComponents alloc] init];
    [minutesToNextQuarterComponents setMinute:minutesToNextQuarter];
	NSDate *regionTimerDate = [calendar dateByAddingComponents:minutesToNextQuarterComponents toDate:minuteTimerDate options:0];

	timer = [[NSTimer alloc] initWithFireDate:regionTimerDate interval:15*60 target:self selector:@selector(updateRegions:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	self.regionsTimer = timer;
}


- (void)viewWillDisappear:(BOOL)animated {
	self.minuteTimer = nil;
	self.regionsTimer = nil;
}


#pragma mark - Update events

- (void)updateTime:(NSTimer *)timer {
    /*
     To display the current time, redisplay the time labels.
     Don't reload the table view's data as this is unnecessarily expensive -- it recalculates the number of cells and the height of each item to determine the total height of the view etc.  The external dimensions of the cells haven't changed, just their contents.
     */
    NSArray *visibleCells = self.tableView.visibleCells;
    for (APLTimeZoneCell *cell in visibleCells) {
        [cell redisplay];
    }
}


- (void)updateRegions:(id)sender {
	/*
	 The following sets the date for the regions, hence also for the time zone wrappers. This has the side-effect of "faulting" the time zone wrappers (see TimeZoneWrapper's setDate: method), so can be used to relieve memory pressure.
	 */
	NSDate *date = [NSDate date];
	for (APLRegion *region in self.displayList) {
		[region setDate:date];
	}
}


#pragma mark - Timer set accessor methods

- (void)setMinuteTimer:(NSTimer *)newTimer {

	if (_minuteTimer != newTimer) {
		[_minuteTimer invalidate];
		_minuteTimer = newTimer;
	}
}


- (void)setRegionsTimer:(NSTimer *)newTimer {

	if (_regionsTimer != newTimer) {
		[_regionsTimer invalidate];
		_regionsTimer = newTimer;
	}
}


#pragma mark - Memory management

- (void)didReceiveMemoryWarning {

	[super didReceiveMemoryWarning];
	[self updateRegions:self];
}


- (void)dealloc {
	[_minuteTimer invalidate];
	[_regionsTimer invalidate];
}

@end
