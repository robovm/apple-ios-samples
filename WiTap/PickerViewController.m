/*
     File: PickerViewController.m
 Abstract: Displays a table of services that the user can pick.
  Version: 2.1
 
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

#import "PickerViewController.h"

@import QuartzCore;

@interface PickerViewController () <NSNetServiceBrowserDelegate>

@property (nonatomic, strong, readwrite) IBOutlet UILabel *     localServiceNameLabel;

@property (nonatomic, strong, readwrite) UIFont *               localServiceNameLabelFont;      // latched from localServiceNameLabel

@property (nonatomic, strong, readwrite) IBOutlet UIView *      connectView;
@property (nonatomic, strong, readwrite) IBOutlet UILabel *     connectLabel;

@property (nonatomic, copy,   readwrite) NSString *             connectLabelTemplate;           // latched from connectLabel

@property (nonatomic, strong, readonly ) NSMutableArray *       services;                       // of NSNetService, sorted by name
@property (nonatomic, strong, readwrite) NSNetServiceBrowser *  browser;

@end

@implementation PickerViewController

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self->_services = [[NSMutableArray alloc] init];
    // We observe localService so that we can react to the client changing it.
    [self addObserver:self forKeyPath:@"localService" options:0 context:&self->_localService];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"localService" context:&self->_localService];
}

- (void)setupLocalServiceNameLabel
    // Called to set the local service name label in response to a change in the local service. 
    // It sets the label to either the actual name or "registering" if there's no local service.
{
    assert(self.localServiceNameLabel != nil);
    if (self.localService == nil) {
        self.localServiceNameLabel.font = [UIFont italicSystemFontOfSize:self.localServiceNameLabelFont.pointSize * 0.75f];
        self.localServiceNameLabel.text = @"registering…";
    } else {
        self.localServiceNameLabel.font = self.localServiceNameLabelFont;
        self.localServiceNameLabel.text = self.localService.name;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->_localService) {
        assert([keyPath isEqual:@"localService"]);
        assert(object == self);
        
        // If there's a local service name label (that is, -viewDidLoad has been called), updated it.
        
        if (self.localServiceNameLabel != nil) {
            [self setupLocalServiceNameLabel];
        }
        
        // There's a chance that the browser saw our service before we heard about its successful 
        // registration, at which point we need to hide the service.  Doing that would be easy, 
        // but there are other edge cases to consider (for example, if the local service changes 
        // name, we would have to unhide the old name and hide the new name).  Rather than attempt 
        // to handle all of those edge cases we just stop and restart when the service name changes.
        
        if (self.browser != nil) {
            [self stop];
            [self start];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    assert(self.localServiceNameLabel != nil);
    assert(self.connectView  != nil);
    assert(self.connectLabel != nil);

    // Stash the original font for use by -setupLocalServiceNameLabel then call 
    // -setupLocalServiceNameLabel to apply the local service to our header.
    
    self.localServiceNameLabelFont = self.localServiceNameLabel.font;       
    [self setupLocalServiceNameLabel];

    // Set up the connect view and stash the label text for use as a template.

    self.connectView.layer.cornerRadius = 10.0f;
    self.connectView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.connectView.layer.shadowOffset = CGSizeMake(3.0f, 3.0f);
    self.connectView.layer.shadowOpacity = 0.7f;
    
    self.connectLabelTemplate = self.connectLabel.text;
}

- (void)start
    // See comment in header.
{
    assert([self.services count] == 0);

    assert(self.browser == nil);
    
    self.browser = [[NSNetServiceBrowser alloc] init];
    self.browser.includesPeerToPeer = YES;
    [self.browser setDelegate:self];
    [self.browser searchForServicesOfType:self.type inDomain:@"local"];
}

- (void)stop
    // See comment in header.
{
    [self.browser stop];
    self.browser = nil;

    [self.services removeAllObjects];
    
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

- (void)cancelConnect
    // See comment in header.
{
    [self hideConnectViewAndNotify:NO];
}

#pragma mark * Connection-in-progress UI management

- (void)showConnectViewForService:(NSNetService *)service
    // Shows a view that indicates we're connecting to the specified service.
{
    CGRect  selfViewBounds;

    // Show the connection UI.
    
    assert(self.connectView  != nil);               // views should be loaded
    assert(self.connectLabel != nil);               // ditto
    assert(self.connectView.superview == nil);      // connection view must not be in the view hierarchy
    
    self.connectLabel.text = [NSString stringWithFormat:self.connectLabelTemplate, [service name]];

    selfViewBounds = self.tableView.bounds;
    self.connectView.center = CGPointMake( CGRectGetMidX(selfViewBounds), CGRectGetMidY(selfViewBounds) );
    [self.tableView addSubview:self.connectView];
    
    // Disable user interactions on the table view to prevent the user doing 
    // stuff 'behind' our connection-in-progress UI.
     
    self.tableView.scrollEnabled = NO;
    self.tableView.allowsSelection = NO;

    // Tell the delegate.
    
    [self.delegate pickerViewController:self connectToService:service];
}

- (void)hideConnectViewAndNotify:(BOOL)notify
    // Hide the view we showed in -showConnectViewForService:
{
    if (self.connectView.superview != nil) {
        [self.connectView removeFromSuperview];

        self.tableView.scrollEnabled = YES;
        self.tableView.allowsSelection = YES;
    }
    if (notify) {
        [self.delegate pickerViewControllerDidCancelConnect:self];
    }
}

- (IBAction)connectCancelAction:(id)sender
    // Called when the user taps the Cancel button in the connection UI.  This hides the 
    // connection UI and tells the delegate about the cancellation.
{
    #pragma unused(sender)
    [self hideConnectViewAndNotify:YES];
}

#pragma mark * Table view callbacks

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    #pragma unused(tableView)
    #pragma unused(section)
    return (NSInteger) [self.services count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *	cell;
    NSNetService *      service;

    #pragma unused(tableView)
    
    service = [self.services objectAtIndex:(NSUInteger) indexPath.row];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];

    cell.textLabel.text = service.name;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNetService *      service;

    #pragma unused(tableView)
    #pragma unused(indexPath)

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Find the service associated with the cell and start a connection to that.
    
    service = [self.services objectAtIndex:(NSUInteger) indexPath.row];
    [self showConnectViewForService:service];
}

#pragma mark * Browser view callbacks

- (void)sortAndReloadTable
{
    // Sort the services by name.

    [self.services sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 name] localizedCaseInsensitiveCompare:[obj2 name]];
    }];
    
    // Reload if the view is loaded.
    
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    assert(browser == self.browser);
    #pragma unused(browser)
    assert(service != nil);
    
    // Remove the service from our array (assume it's there, of course).
    
    if ( (self.localService == nil) || ! [self.localService isEqual:service] ) {
        [self.services removeObject:service];
    }
    
    // Only update the UI once we get the no-more-coming indication.
    
    if ( ! moreComing ) {
        [self sortAndReloadTable];
    }
}   

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    assert(browser == self.browser);
    #pragma unused(browser)
    assert(service != nil);
    
    // Add the service to our array (unless its our own service).

    if ( (self.localService == nil) || ! [self.localService isEqual:service] ) {
        [self.services addObject:service];
    }

    // Only update the UI once we get the no-more-coming indication.

    if ( ! moreComing ) {
        [self sortAndReloadTable];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary *)errorDict
{
    assert(browser == self.browser);
    #pragma unused(browser)
    assert(errorDict != nil);
    #pragma unused(errorDict)
    assert(NO);         // The usual reason for us not searching is a programming error.
}

@end
