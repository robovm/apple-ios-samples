/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The main UIViewController containing the app's user interface.
 */

#import "RootViewController.h"

// The value for the 'Text Color' setting is stored as an integer between
// one and three inclusive.  This enumeration provides a mapping between
// the integer value, and color.
typedef NS_ENUM(NSUInteger, TextColor) {
    blue = 1,
    red,
    green
};


// It's best practice to define constant strings for each preference's key.
// These constants should be defined in a location that is visible to all
// source files that will be accessing the preferences.
NSString* const kFirstNameKey			= @"firstNameKey";
NSString* const kLastNameKey			= @"lastNameKey";
NSString* const kNameColorKey			= @"nameColorKey";


@interface RootViewController ()

// Values from the app's preferences
@property (strong) NSString *firstName;
@property (strong) NSString *lastName;
@property (strong) UIColor *nameColor;

@end


@implementation RootViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Only iOS 8 and above supports the UIApplicationOpenSettingsURLString
    // used to launch the Settings app from your application.  If the
    // UIApplicationOpenSettingsURLString is not present, we're running on an
    // old version of iOS.  Remove the Settings button from the navigation bar
    // since it won't be able to do anything.
    if (&UIApplicationOpenSettingsURLString == NULL) {
        self.navigationItem.leftBarButtonItem = nil;
    }
}


//| ----------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Load our preferences.  Preloading the relevant preferences here will
    // prevent possible diskIO latency from stalling our code in more time
    // critical areas, such as tableView:cellForRowAtIndexPath:, where the
    // values associated with these preferences are actually needed.
    [self onDefaultsChanged:nil];
    
    // Begin listening for changes to our preferences when the Settings app does
    // so, when we are resumed from the backround, this will give us a chance to
    // update our UI
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDefaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}


//| ----------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Stop listening for the NSUserDefaultsDidChangeNotification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
}


//| ----------------------------------------------------------------------------
//! Unwind action for the Done button on the Info screen.
//
- (IBAction)unwindFromInfoScreen:(UIStoryboardSegue *)sender
{ }

#pragma mark -
#pragma mark Preferences

//| ----------------------------------------------------------------------------
//! Launches the Settings app.  The Settings app will automatically navigate to
//! to the settings page for this app.
//
- (IBAction)openApplicationSettings:(id)sender
{
    // UIApplicationOpenSettingsURLString is only availiable in iOS 8 and above.
    // The following code will crash if run on a prior version of iOS.  See the
    // check in -viewDidLoad.
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}


//| ----------------------------------------------------------------------------
//  Handler for the NSUserDefaultsDidChangeNotification.  Loads the preferences
//  from the defaults database into the holding properies, then asks the
//  tableView to reload itself.
//
- (void)onDefaultsChanged:(NSNotification *)aNotification
{
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    
    self.firstName = [standardDefaults objectForKey:kFirstNameKey];
    self.lastName = [standardDefaults objectForKey:kLastNameKey];
    
    // The value for the 'Text Color' setting is stored as an integer between
    // one and three inclusive.  Convert the integer into a UIColor object.
    TextColor textColor = [standardDefaults integerForKey:kNameColorKey];
    switch (textColor) {
        case blue:
            self.nameColor = [UIColor blueColor];
            break;
        case red:
            self.nameColor = [UIColor redColor];
            break;
        case green:
            self.nameColor = [UIColor greenColor];
            break;
        default:
            NSAssert(NO, @"Got an unexpected value %@ for %@", @(textColor), kNameColorKey);
    }
    
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark UITableViewDataSource

//| ----------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}


//| ----------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NameCell"];

	cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
	cell.textLabel.textColor = self.nameColor;
	
	return cell;
}

@end

