
/*
     File: APLEventsTableViewController.m
 Abstract: The table view controller responsible for displaying the list of events, supporting additional functionality:
 * Addition of new events;
 * Deletion of existing events using UITableView's tableView:commitEditingStyle:forRowAtIndexPath: method.
 * Editing an event's name.
 
  Version: 2.3
 
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


#import "APLEventsTableViewController.h"
#import "APLEventTableViewCell.h"
#import "APLTagSelectionController.h"

#import "APLEvent.h"
#import "APLTag.h"

@interface APLEventsTableViewController ()

@property (nonatomic) NSMutableArray *eventsArray;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *addButton;

@end



@implementation APLEventsTableViewController


#pragma mark - View lifecycle

- (void)viewDidLoad
{	
    [super viewDidLoad];

    // Configure the add and edit buttons.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

	/*
	 Fetch existing events.
	 Create a fetch request for the Event entity; add a sort descriptor; then execute the fetch.
	 */
	NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"APLEvent"];
	[request setFetchBatchSize:20];
    
	// Order the events by creation date, most recent first.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	NSArray *sortDescriptors = @[sortDescriptor];
	[request setSortDescriptors:sortDescriptors];
	
	// Execute the fetch.
	NSError *error;
	NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
	}

	// Set self's events array to a mutable copy of the fetch results.
	[self setEventsArray:[fetchResults mutableCopy]];
    
    /*
     Reload the table view if the locale changes -- look at APLEventTableViewCell.m to see how the table view cells are redisplayed.
     */
    __weak UITableViewController *weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:NSCurrentLocaleDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        [weakSelf.tableView reloadData];
    }];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[self.tableView reloadData];

	// Start the location manager.
	[self.locationManager startUpdatingLocation];
}


- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	self.locationManager = nil;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Table view data source methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// There is only one section.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// There are as many rows as there are obects in the events array.
    return [self.eventsArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"EventTableViewCell";

    APLEventTableViewCell *cell = (APLEventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.delegate = self;

	// Get the event corresponding to the current index path and configure the table view cell.
	APLEvent *event = (APLEvent *)self.eventsArray[indexPath.row];
    [cell configureWithEvent:event];
    
	return cell;
}


#pragma mark - Editing

/*
 Handle deletion of an event.
 */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		// Ensure that if the user is editing a name field then the change is committed before deleting a row -- this ensures that changes are made to the correct event object.
		[tableView endEditing:YES];
		
        // Delete the managed object at the given index path.
		NSManagedObject *eventToDelete = (self.eventsArray)[indexPath.row];
		[self.managedObjectContext deleteObject:eventToDelete];
		
		// Update the array and table view.
        [self.eventsArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		
		// Commit the change.
		NSError *error;
		if (![self.managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
		}
    }
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
	self.navigationItem.rightBarButtonItem.enabled = !editing;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"EditTags"]) {
         
        APLEventTableViewCell *cell = (APLEventTableViewCell *)sender;
        
        [cell endEditing:YES];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        APLTagSelectionController *tagSelectionController = [segue destinationViewController];
        tagSelectionController.event = (self.eventsArray)[indexPath.row];
    }
}


#pragma mark - Add an event

/*
 Add an event.
 */
- (IBAction)addEvent:(id)sender
{	
	// If it's not possible to get a location, then return.
	CLLocation *location = [self.locationManager location];
	if (!location) {
#ifdef DEBUG
        CLLocationDegrees latitude = random() * 720.0 / INT32_MAX  - 360.0;;
        CLLocationDegrees longitude = random() * 720.0 / INT32_MAX  - 360.0;;
        location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
#else
        return;
#endif
	}
	
	/*
	 Create a new instance of the Event entity.
	 */
	APLEvent *event = (APLEvent *)[NSEntityDescription insertNewObjectForEntityForName:@"APLEvent" inManagedObjectContext:self.managedObjectContext];
	
	// Configure the new event with information from the location.
    event.creationDate = location.timestamp;
	CLLocationCoordinate2D coordinate = location.coordinate;
	event.latitude = @(coordinate.latitude);
	event.longitude = @(coordinate.longitude);
	
	/*
	 Because this is a new event, and events are displayed with most recent events at the top of the list, add the new event to the beginning of the events array, then:
	 * Add a new row to the table view
	 * Scroll to make the row visible
	 * Start editing the name field
	 */
    [self.eventsArray insertObject:event atIndex:0];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	
	[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];

	[self setEditing:YES animated:YES];
	APLEventTableViewCell *cell = (APLEventTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
	[cell makeNameFieldFirstResponder];
	
	/*
	 Don't save yet -- the name is not optional:
	 * The user should add a name before the event is saved.
	 * If the user doesn't add a name, it will be set to @"" when they press Done.
	 */
}


#pragma mark - Editing text fields

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    CGPoint point = [textField center];
    point = [self.tableView convertPoint:point fromView:textField];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
	APLEvent *event = (self.eventsArray)[indexPath.row];
	event.name = textField.text;
	
	// Commit the change.
	NSError *error;
	if (![self.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
	}

	return YES;
}	


- (void)textFieldDidEndEditing:(UITextField *)textField
{
	/*
     Ensure that a text field for a row for a newly-inserted object is disabled when the user finishes editing.
	 */
    textField.enabled = self.editing;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;	
}


#pragma mark - Location manager

/*
 Return a location manager -- create one if necessary.
 */
- (CLLocationManager *)locationManager
{
    if (_locationManager != nil) {
		return _locationManager;
	}

	_locationManager = [[CLLocationManager alloc] init];
	[_locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
	[_locationManager setDelegate:self];

	return _locationManager;
}


/*
 Conditionally enable the Add button:
 If the location manager is generating updates, then enable the button;
 If the location manager is failing, then disable the button.
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if (!self.editing) {
		self.addButton.enabled = YES;
	}
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
#ifdef DEBUG
    NSLog(@"Location manager failed");
#else
    self.addButton.enabled = NO;
#endif
}


@end

