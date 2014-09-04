/*
     File: RootViewController.m
 Abstract: Top-level view controller containing table of mountains.
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

#import "RootViewController.h"
#import "DetailViewController.h"

/* key name for the application preference in our Settings.bundle */
NSString *kSettingKey = @"sort";

// key for Mountain name, constant string declared in DetailViewController
extern const NSString *kMountainNameString;

@interface RootViewController ()
@property (nonatomic, strong) NSArray *mountains;
@end


#pragma mark -

/* A C-function used as the comparator for our call to
 NSArray:sortedArrayUsingFunction below.  Uses NSString:localizedCompare */
NSInteger mountainSort(id m1, id m2, void *context) {
    
	/* A private comparator fcn to sort two mountains.  To do so,
	 we do a localized compare of mountain names, using
	 NSString:localizedCompare. */
	NSString *m1Name = @"";
	NSString *m2Name = @"";
	if (m1 != nil && [m1 isKindOfClass:[NSDictionary class]] &&
		m2 != nil && [m2 isKindOfClass:[NSDictionary class]]) {
		m1Name = ((NSDictionary *) m1)[kMountainNameString];
		m2Name = ((NSDictionary *) m2)[kMountainNameString];
	}
	return [m1Name localizedCompare:m2Name];
}



@implementation RootViewController

#pragma mark - UIViewController Overridables
- (void)viewDidLoad {
    
	[super viewDidLoad];
    
	/* Create and load our mountain data array, which will access the correct
     localized Mountains.plist from the application bundle. */
	[self loadMountainsWithBundle:[NSBundle mainBundle]];
    
    /* Get the current "sort" application preference (creating if it
     doesn't exist yet) and if enabled (the default), sort the mountain list */
	if ([self getSortAppPref]) {
	    _mountains = [self.mountains sortedArrayUsingFunction:mountainSort context:nil];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        
        DetailViewController *detailViewController = [segue destinationViewController];
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        detailViewController.mountainDictionary = self.mountains[indexPath.row];
    }
}


#pragma mark - Notification Handler

- (void)appDidBecomeActive:(NSNotification *)notif {
    
    // When user changed the setting and back to the app, we are notified here to
    // update the table view. We simply reload the mountains data and upadte the tableview
    //
    [self loadMountainsWithBundle:[NSBundle mainBundle]];
	if ([self getSortAppPref]) {
	    _mountains = [self.mountains sortedArrayUsingFunction:mountainSort context:nil];
    }
    [self.tableView reloadData];
}


#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
	return self.mountains.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

	/* Get the text to display in the tableview cell.  We've already loaded
     the localized mountain name from the bundle data using loadMountainsWithBundle */
	NSDictionary *mountainDictionary = self.mountains[indexPath.row];
	cell.textLabel.text = mountainDictionary[kMountainNameString];
    return cell;
}

#pragma mark - Helper methods

- (BOOL)getSortAppPref {
    
	/* As this application provides a Settings.bundle for application
     preferences, the following is a simple example that retrieves the
     current user-set preferences. */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
	/* Similar to the AppPrefs sample, we first test to see if the preferences
     settings exist, and create if needed. */
	if ([defaults dataForKey:kSettingKey] == nil) {
        
		NSString *pathStr = [[NSBundle mainBundle] bundlePath];
		NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
		NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];
        
		NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
		NSArray *prefSpecifierArray = settingsDict[@"PreferenceSpecifiers"];
		NSNumber *settingDefault = nil;
		NSDictionary *prefItem;
		
		for (prefItem in prefSpecifierArray) {
            
			NSString *keyValueStr = prefItem[@"Key"];
			id defaultValue = prefItem[@"DefaultValue"];
			
			if ([keyValueStr isEqualToString:kSettingKey]) {
				settingDefault = defaultValue;
			}
		}
		
		if (settingDefault != nil) {
            
			NSDictionary *appDefaults = @{kSettingKey: settingDefault};
			[defaults registerDefaults:appDefaults];
			[defaults synchronize];
		}
	}
	return [defaults boolForKey:kSettingKey];
}

- (void)loadMountainsWithBundle:(NSBundle *)bundle {
    
	if (bundle != nil) {
		/* Read the mountain data in from the app bundle, relying on the system to
		 properly give us the correct, localized version of the data file
		 (Mountains.plist) based on current user language setting.
		 Note: While this sample uses plists for the localized data source,
		 there are many other options (sqlite db, flat file, etc) that can
		 all be localized as long as they are available in properly set-up
		 localized project resource folders. */
		NSString *path = [bundle pathForResource:@"Mountains" ofType:@"plist"];
		NSArray *mountainList = (path != nil ? [NSArray arrayWithContentsOfFile:path] : nil);
		NSMutableArray *array = [NSMutableArray arrayWithCapacity:
								 (mountainList != nil ? [mountainList count] : 0)];
		for (NSDictionary *mountainDict in mountainList) {
			/* add the given mountain dictionary to our array */
			[array addObject:mountainDict];
		}
		/* Copy into our non-mutable array */
		_mountains = [[NSArray alloc] initWithArray:array];
	}
}

@end
