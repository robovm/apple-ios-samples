
/*
     File: APLViewController.m
 Abstract: View controller that serves as the table view's data source and delegate. It uses the current UILocalizedIndexedCollation object to organize the time zones into appropriate sections, and also to provide information about section titles and section index titles.
 
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
#import "APLAppDelegate.h"

#import "APLTimeZoneWrapper.h"

// The sections array and the collation are private.
@interface APLViewController ()
@property (nonatomic) NSMutableArray *sectionsArray;
@property (nonatomic) UILocalizedIndexedCollation *collation;
- (void)configureSections;
@end


@implementation APLViewController


#pragma mark - Table view data source and delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// The number of sections is the same as the number of titles in the collation.
    return [[self.collation sectionTitles] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	// The number of time zones in the section is the count of the array associated with the section in the sections array.
	NSArray *timeZonesInSection = (self.sectionsArray)[section];

    return [timeZonesInSection count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"MyIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	// Get the time zone from the array associated with the section index in the sections array.
	NSArray *timeZonesInSection = (self.sectionsArray)[indexPath.section];

	// Configure the cell with the time zone's name.
	APLTimeZoneWrapper *timeZone = timeZonesInSection[indexPath.row];
    cell.textLabel.text = timeZone.localeName;

    return cell;
}


/*
 Section-related methods: Retrieve the section titles and section index titles from the collation.
 */

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.collation sectionTitles][section];
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self.collation sectionIndexTitles];
}


- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.collation sectionForSectionIndexTitleAtIndex:index];
}


#pragma mark - Set the data array and configure the section data

/*
 Configuring the sections is a little fiddly, and it's not directly relevant to understanding how sectioned table views themselves work, so there's no need to work though these methods if you don't want to.
 */

- (void)setTimeZonesArray:(NSMutableArray *)newDataArray {
    
	if (newDataArray != _timeZonesArray) {
		_timeZonesArray = [newDataArray mutableCopy];
        if (_timeZonesArray == nil) {
            self.sectionsArray = nil;
        }
        else {
            [self configureSections];
        }
	}
}


- (void)configureSections {

	// Get the current collation and keep a reference to it.
	self.collation = [UILocalizedIndexedCollation currentCollation];

	NSInteger index, sectionTitlesCount = [[self.collation sectionTitles] count];

	NSMutableArray *newSectionsArray = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];

	// Set up the sections array: elements are mutable arrays that will contain the time zones for that section.
	for (index = 0; index < sectionTitlesCount; index++) {
		NSMutableArray *array = [[NSMutableArray alloc] init];
		[newSectionsArray addObject:array];
	}

	// Segregate the time zones into the appropriate arrays.
	for (APLTimeZoneWrapper *timeZone in self.timeZonesArray) {

		// Ask the collation which section number the time zone belongs in, based on its locale name.
		NSInteger sectionNumber = [self.collation sectionForObject:timeZone collationStringSelector:@selector(localeName)];

		// Get the array for the section.
		NSMutableArray *sectionTimeZones = newSectionsArray[sectionNumber];

		//  Add the time zone to the section.
		[sectionTimeZones addObject:timeZone];
	}

	// Now that all the data's in place, each section array needs to be sorted.
	for (index = 0; index < sectionTitlesCount; index++) {

		NSMutableArray *timeZonesArrayForSection = newSectionsArray[index];

		// If the table view or its contents were editable, you would make a mutable copy here.
		NSArray *sortedTimeZonesArrayForSection = [self.collation sortedArrayFromArray:timeZonesArrayForSection collationStringSelector:@selector(localeName)];

		// Replace the existing array with the sorted array.
		newSectionsArray[index] = sortedTimeZonesArrayForSection;
	}

	self.sectionsArray = newSectionsArray;
}


@end

