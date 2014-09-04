/*
     File: DetailViewController.m
 Abstract: A simple UIViewController that shows a localized label that contains detail information, including height and date data, about the user-selected mountain.
  Version: 1.3
 
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "DetailViewController.h"

// key names for values in mountain dictionary entries
const NSString *kMountainNameString = @"name";
const NSString *kMountainHeightString = @"height";
const NSString *kMountainClimbedDateString = @"climbedDate";

@interface DetailViewController () {
    
	// Private formatter instances that we'll re-use
	NSNumberFormatter *numberFormatter;
	NSDateFormatter *dateFormatter;
}
@property (weak, nonatomic) IBOutlet UILabel *mountainDetails;
@end


@implementation DetailViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
        
    [self updateLabelWithMountainName:self.mountainDictionary[kMountainNameString]
                               height:self.mountainDictionary[kMountainHeightString]
                          climbedDate:self.mountainDictionary[kMountainClimbedDateString]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentLocaleOrTimeZoneDidChange:)
                                                 name:NSCurrentLocaleDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentLocaleOrTimeZoneDidChange:)
                                                 name:NSSystemTimeZoneDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews {
    
    [self.mountainDetails setPreferredMaxLayoutWidth:self.mountainDetails.bounds.size.width];
    [self.view layoutIfNeeded];
}


#pragma mark - Notification Handler

- (void)currentLocaleOrTimeZoneDidChange:(NSNotification *)notif {
    
    // When user changed the locale (region format) or time zone in Settings, we are notified here to
    // update the date format in UI.
    //
    [self updateLabelWithMountainName:self.mountainDictionary[kMountainNameString]
                               height:self.mountainDictionary[kMountainHeightString]
                          climbedDate:self.mountainDictionary[kMountainClimbedDateString]];
}


#pragma mark - Helper Methods

- (void)updateLabelWithMountainName:(NSString *)name height:(NSNumber*)height climbedDate:(NSDate*)climbedDate {
    
	/* Create the localized UI label in the detail view using Localizable.strings
	 and the passed-in mountain information.  climbedDate is optional. */
	NSString *sentence = @"";
	NSString *format;
	if (climbedDate != nil) {
		format = NSLocalizedString(@"sentenceFormat",
								   @"A sentence with the mountain's name (first parameter), height (second parameter), and climbed date (third parameter)");
		sentence = [NSString stringWithFormat:format,
					name, [self heightAsString:height], [self dateAsString:climbedDate]];
	} else {
		/* Some mountains do not have a climbed date in our database, so use
		 an alternate label sentence for these. */
		format = NSLocalizedString(@"undatedSentenceFormat",
								   @"A sentence with the mountain's name (first parameter), and height (second parameter), but no climbed date");
		sentence = [NSString stringWithFormat:format,
					name, [self heightAsString:height]];
	}
	/* Note that the mountainDetails UILabel is defined in Interface Builder as
	 a multi-line UILabel.  This was done by setting the "Layout, # Lines" setting
	 to 0, and the "Font Size, Adjust to Fit" to off. */
	self.mountainDetails.text = sentence;
	/* Note that by setting the text property on the mountainDetails UILabel,
	 it automatically gets invalidated so we do not need to call setNeedsDisplay */
}

- (NSString*)heightAsString:(NSNumber*)heightNumber {
    
	/* Create a single string expressing a mountain's height.  Based on the
     Region Format (as determined using NSLocale information), we need to
     allow for the possibility that the user is using either metric or
     non-metric units.  If the units are non-metric, we will need to manually
     convert.  Also, note that we need to use the properly localized measurement
     units format (meters/feet) as NSFormatter does not handle measurement
     units (although it will handle decimal numbers for us). */
	NSString *returnValue = @"";
	if (heightNumber != nil) {
		NSString *format = @"%d";
		NSInteger height = [heightNumber integerValue];
		NSNumber *usesMetricSystem = [[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem];
		if (usesMetricSystem != nil && ![usesMetricSystem boolValue]) {
			/* Convert the height to feet */
			height = (int) ((float) height * 3.280839895);
			format = NSLocalizedString(@"footFormat", @"Use to express a height in feet");
		} else {
			format = NSLocalizedString(@"meterFormat", @"Use to express a height in meters");
		}
		/* Specify we want the "new" 10.4 NSNumberFormatter behavior */
		[NSNumberFormatter setDefaultFormatterBehavior:NSNumberFormatterBehavior10_4];
		/* Use a NSNumberFormatter for properly formatting decimal values for the
         current locale/region format settings.  For the measurement string, we've
         already loaded the localized string above. */
		if (numberFormatter == nil) {
			numberFormatter = [[NSNumberFormatter alloc] init];
		}
		[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		returnValue = [NSString stringWithFormat:format, [numberFormatter stringFromNumber:@(height)]];
	}
	return returnValue;
}

- (NSString*)dateAsString:(NSDate*)date {
    
	/* Create a single string expressing a mountain's climbed date, properly localized */
	NSString *returnValue = @"";
	if (date != nil) {
		if (dateFormatter == nil) {
			dateFormatter = [[NSDateFormatter alloc] init];
		}
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setLocale:[NSLocale currentLocale]];
		returnValue = [dateFormatter stringFromDate:date];
	}
	/* As this code uses the current "locale", the date format will be in the format
     specified by the user's "Region Format" settings.  If you need to use an
     alternate format internally, you can create and use NSLocales, e.g.:
	 
     NSLocale *enGBLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
     [numberFormatter setLocale:enGBLocale];
	 
     Doing so will not affect the current user-set language or region format.
     
     Similarly, while you should always rely on the system and application bundle
     to pick the most appropriate resources for the current user language setting,
     if you need to know what the current user language setting is, you can do
     something like the following:
	 
     NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
     NSArray* languages = [defs objectForKey:@"AppleLanguages"];
     NSString* preferredLang = [languages objectAtIndex:0];
     NSLog(@"Current language is %@", preferredLang);
	 
     Note that the iPhone does not support locales in the same way that Mac OS
     does (really only using locales for the Region Format settings) so if you
     try and get an array from standardUserDefaults for the key "AppleLocale",
     this will fail on the iPhone. */
	return returnValue;
}

@end
