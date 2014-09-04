/*
     File: RootViewController.m
 Abstract: The main UIViewController containing the app's user interface.
  Version: 1.6
 
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

#import "RootViewController.h"

// The value for the 'Text Color' setting is stored as an integer between
// one and three inclusive.  This enumeration provides a mapping between
// the integer value, and color.
enum TextColors
{
	blue = 1,
	red,
	green
};

// It's good practice to define constant strings for each preference's key.
// These constants should be defined in a location that is visible to all
// source files that will be accessing the preferences.
NSString* const kFirstNameKey			= @"firstNameKey";
NSString* const kLastNameKey			= @"lastNameKey";
NSString* const kNameColorKey			= @"nameColorKey";


@interface RootViewController ()

// Things for IB
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIView *instructionsView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;

@property (nonatomic, strong) UIBarButtonItem *flipButton;

// Values from the app's preferences
@property (strong) NSString *firstName;
@property (strong) NSString *lastName;
@property (strong) UIColor *nameColor;

@end


@implementation RootViewController

#pragma mark - View Controller Lifecycle

// -------------------------------------------------------------------------------
//	viewDidLoad
// -------------------------------------------------------------------------------
- (void)viewDidLoad
{
	// Add a custom flip button as the nav bar's custom right view
	UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self action:@selector(flipAction:) forControlEvents:UIControlEventTouchUpInside];
	self.flipButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
	self.navigationItem.rightBarButtonItem = self.flipButton;
}

// -------------------------------------------------------------------------------
//	viewWillAppear:
// -------------------------------------------------------------------------------
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

// -------------------------------------------------------------------------------
//	viewWillDisappear:
// -------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
    // Stop listening for the NSUserDefaultsDidChangeNotification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
// -------------------------------------------------------------------------------
//	viewDidUnload
//  This method is only called on iOS 5 and below.  iOS 6 does not unload its
//  view in response to memory warnings.
// -------------------------------------------------------------------------------
- (void)viewDidUnload
{
	self.doneButton = nil;
	self.flipButton = nil;
}
#endif

#pragma mark - Preferences

// -------------------------------------------------------------------------------
//	onDefaultsChanged:
//  Handler for the NSUserDefaultsDidChangeNotification.  Loads the preferences
//  from the defaults database into the holding properies, then asks the
//  tableView to reload itself.
// -------------------------------------------------------------------------------
- (void)onDefaultsChanged:(NSNotification*)aNotification
{
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    
    self.firstName = [standardDefaults objectForKey:kFirstNameKey];
    self.lastName = [standardDefaults objectForKey:kLastNameKey];
    
    // The value for the 'Text Color' setting is stored as an integer between
    // one and three inclusive.  Convert the integer into a UIColor object.
    switch ([standardDefaults integerForKey:kNameColorKey]) {
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
            break;
    }
    
    [self.tableView reloadData];
}

#pragma mark - Flip screen

// -------------------------------------------------------------------------------
//	flipAction:
//  IBAction for the 'done' and 'info' buttons.
//  Transitions between the tableView and the 'instructionsView'.
// -------------------------------------------------------------------------------
- (IBAction)flipAction:(id)sender
{
    NSUInteger transitionType = (self.tableView.hidden ? UIViewAnimationOptionTransitionFlipFromRight : UIViewAnimationOptionTransitionFlipFromLeft);
    
    [UIView transitionWithView:self.view
                      duration:0.75
                       options:transitionType
                    animations:^{
                         self.tableView.hidden = !self.tableView.hidden;
                         self.instructionsView.hidden = !self.instructionsView.hidden;
                     }
                    completion:NULL];
    
    // Adjust the done/info buttons accordingly
    if (self.tableView.hidden)
        self.navigationItem.rightBarButtonItem = self.doneButton;
    else
        self.navigationItem.rightBarButtonItem = self.flipButton;
	
}

#pragma mark - UITableViewDataSource

// -------------------------------------------------------------------------------
//	tableView:numberOfRowsInSection:
// -------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

// -------------------------------------------------------------------------------
//	tableView:cellForRowAtIndexPath:
// -------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NameCell"];

	cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
	cell.textLabel.textColor = self.nameColor;
	
	return cell;
}

#pragma mark - UITableViewDelegate

// -------------------------------------------------------------------------------
//	tableView:didSelectRowAtIndexPath:
//  Deselects the row when the user taps on it.
// -------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

