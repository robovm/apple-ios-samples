/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The application's primary table view controller showing the list of CKRecord photos.
 */

#import "APLAppDelegate.h"
#import "APLMainTableViewController.h"
#import "APLDetailTableViewController.h"
#import "APLCloudManager.h"

@import CloudKit;
@import CoreLocation;   // for tracking user's location and CLGeocoder

static NSString * const kCellIdentifier = @"cellID";

// scope bar indexes for UISearchBar
enum ScopeIndexes {
    kAllScope,
    kMineScope,
    kRecentScope,
    kNearMeScope
};

// view tags for our table cells
#define kNoPhotosLabelTag 99
#define kTitleLabelTag 2
#define kPhotoTag 1
#define kOwnerLabelTag 3


@interface APLMainTableViewController () <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, CLLocationManagerDelegate>

@property (nonatomic, strong) NSMutableArray *records;
@property (nonatomic, strong) NSArray *filteredRecords;

@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *addButton;

// for state restoration
@property BOOL restoringSearchState;
@property BOOL searchControllerWasActive;
@property BOOL searchControllerSearchFieldWasFirstResponder;
@property (nonatomic, strong) NSString *searchControllerText;
@property (assign) NSInteger searchControllerScopeIndex;

@property BOOL searchControllerActiveFromPreviousView;

// for tracking user location
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) CLGeocoder *geocoder;

@property (nonatomic, strong) NSLayoutConstraint *labelConstraintForX;
@property (nonatomic, strong) NSLayoutConstraint *labelConstraintForY;

@end


#pragma mark -

@implementation APLMainTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = nil;    // we aren't ready yet to populate our photo list
    
    _geocoder = [[CLGeocoder alloc] init];  // so we can show the user the city and state a given photo was taken
    
    _locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager requestWhenInUseAuthorization];   // ask for user permission to find our location, we use this to find photos near us
    
    // setup our search display controller for searching records
    //
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO; // default is YES
    
    self.searchController.searchBar.delegate = self; // so we can monitor text changes + others
    self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;

    // Search is now just presenting a view controller. As such, normal view controller
    // presentation semantics apply. Namely that presentation will walk up the view controller
    // hierarchy until it finds the root view controller or one that defines a presentation context.
    //
    self.definesPresentationContext = YES;  // know where you want UISearchController to be displayed
    
    // create our refresh control so users can rescan for photos
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] initWithFrame:CGRectZero];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    // while in table edit mode, we allow for "Delete My Photos" feature in the bottom toolbar
    UIBarButtonItem *clearAllButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Delete My Photos", nil)
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(deleteAllAction:)];
    [self setToolbarItems:@[clearAllButton] animated:NO];
    
    // if are are logged in, subscribe to changes to our record type (this will allow for push notifications to other devices)
    [CloudManager accountAvailable:^(BOOL available) {
        [CloudManager subscribe];
    }];
    
    // listen when we are backgrounded (leaving the app)
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      // we are being backgrounded, exit edit mode if necessary
                                                      if (self.isEditing)
                                                      {
                                                          [self setEditing:NO animated:NO];
                                                      }
                                                  }];
    
    // initially add our right Edit button as disabled
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.editButtonItem.enabled = NO;
    
    // first find out who is logged in, then search for photos, finally update our user interface
    [CloudManager updateUserLogin:^() {
        [self loadPhotos:^() {
            [self updateNavigationBar];
        }];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // look for our current location,
    // note: we turn off location updates in didUpdateLocations after we get our first discovery
    //
    [self.locationManager startUpdatingLocation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // restore the searchController's active state
    if (self.searchControllerWasActive)
    {
        // filtering the list of photos isn't possible yet until our fetch completes in "loadPhotos",
        // so filter the table after the fetch completes with this flag
        //
        _restoringSearchState = YES;
        
        self.searchController.active = self.searchControllerWasActive;
        _searchControllerWasActive = NO;    // reset this state for next time
        
        self.searchController.searchBar.text = self.searchControllerText;
        self.searchController.searchBar.selectedScopeButtonIndex = self.searchControllerScopeIndex;
        
        if (self.searchControllerSearchFieldWasFirstResponder)
        {
            [self.searchController.searchBar becomeFirstResponder];
            _searchControllerSearchFieldWasFirstResponder = NO; // reset this state for next time
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // when we are going away or being hidden, stop searching for our location (if we haven't found ourselves yet)
    [self.locationManager stopUpdatingLocation];
    _currentLocation = nil;
}

- (void)dealloc
{
    [self.locationManager stopUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
}


#pragma mark - UI Methods

// update our navigation bar so that the edit and add button states are correct according to user login
- (void)updateNavigationBar
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [CloudManager accountAvailable:^(BOOL available) {
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (available && [CloudManager userLoginIsValid])
        {
            // we are logged in, iCloud drive is on

            // the edit button state should update
            self.editButtonItem.enabled = (self.records.count > 0);
            
            // add button state should match if we have a container to read/write to
            self.addButton.enabled = [CloudManager isContainerAvailable];
        }
        else
        {
            // we are not logged into iCloud
            // or
            // we are logged into iCloud, but iCloud drive is turned off
            //
            // we can just read but can't make any changes
            
            // note: in simulator for iOS 7 or earlier, for accountStatus you get: "CKAccountStatusNoAccount"
            
            // disable the edit and add button
            self.editButtonItem.enabled = NO;
            self.addButton.enabled = NO;
        }
    }];
}

// obtain the index row number of the given recordID, -1 if it cannot be found
- (NSInteger)indexForPhotoWithRecordID:(CKRecordID *)recordID
{
    NSInteger foundIndex = -1;
    
    for (NSInteger rowIdx = 0; rowIdx < self.records.count; rowIdx++)
    {
        CKRecord *photoRecord = self.records[rowIdx];
        if ([photoRecord.recordID isEqual:recordID])
        {
            foundIndex = rowIdx;
            break;  // we found the photo record that needs updating, no need to continue searching
        }
    }
    
    return foundIndex;
}

// called as a result of a subscription notification:
// update just the table cell this CKRecordID is associated with,
// instead of just doing an entire table re-fetch, let's be efficient and just apply the update for the record in question
//
- (void)updateTableWithRecordID:(CKRecordID *)recordID reason:(CKQueryNotificationReason)reason
{
    if (reason == CKQueryNotificationReasonRecordDeleted)
    {
        // we are being asked to remove an existing photo
        NSInteger photoIndex = [self indexForPhotoWithRecordID:recordID];
        CKRecord *foundPhotoRecord = nil;
        
        if (photoIndex != -1)
        {
            // we found a proper photo in our table view to be removed
            foundPhotoRecord = self.records[photoIndex];
            
            // record was removed, remove it from the table
            if (foundPhotoRecord != nil)
            {
                // we found the record that needs removing
                [self.records removeObject:foundPhotoRecord];
                
                // update our table
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:photoIndex inSection:0];
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
            }
        }
    }
    else
    {
        // we are being told a record was added or updated
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        // first we need to fetch that record
        [CloudManager fetchRecordWithID:recordID completionHandler:^(CKRecord *foundRecord, NSError *error) {
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

            if (foundRecord != nil)
            {
                // we have obtained the record to be added or updated
                //
                NSInteger photoIndex = [self indexForPhotoWithRecordID:recordID];
                
                if (reason == CKQueryNotificationReasonRecordUpdated)
                {
                    if (photoIndex >= 0)
                    {
                        // we found the record that needs "updating"
                        //
                        [self.records replaceObjectAtIndex:photoIndex withObject:foundRecord];
                        
                        // update the cell
                        //
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:photoIndex inSection:0];
                        
                        // update the title
                        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                        UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:kTitleLabelTag];
                        titleLabel.text = foundRecord[[APLCloudManager PhotoTitleAttribute]];
                        
                        // update the photo
                        CKAsset *photoAsset = foundRecord[[APLCloudManager PhotoAssetAttribute]];
                        if (photoAsset != nil)
                        {
                            UIImage *imageData = [UIImage imageWithContentsOfFile:[photoAsset.fileURL path]];
                            UIImageView *photoView = (UIImageView *)[cell.contentView viewWithTag:kPhotoTag];
                            photoView.image = imageData;
                        }
                        
                        // resort the list of photos, but keep track of its indexPath so we can move its table cell into the right place
                        NSInteger oldIndexForPhoto = [self indexForPhotoWithRecordID:recordID];
                        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:[APLCloudManager PhotoTitleAttribute] ascending:YES];
                        [self.records sortUsingDescriptors:@[sortDescriptor]];
                        NSInteger newIndexForPhoto = [self indexForPhotoWithRecordID:recordID];
                        
                        NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:oldIndexForPhoto inSection:0];
                        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newIndexForPhoto inSection:0];
                        [self.tableView moveRowAtIndexPath:oldIndexPath toIndexPath:newIndexPath];
                    }
                }
                else if (reason == CKQueryNotificationReasonRecordCreated)
                {
                    if (photoIndex == -1)   // make sure the photo isn't already in the list
                    {
                        // no photos were found on our list, so add this new one
                        [self.records addObject:foundRecord];
                        
                        // resort the list of photos
                        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:[APLCloudManager PhotoTitleAttribute] ascending:YES];
                        [self.records sortUsingDescriptors:@[sortDescriptor]];
                        
                        // update our table
                        NSInteger newIndexForPhoto = [self indexForPhotoWithRecordID:recordID];
                        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newIndexForPhoto inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }
                
                // update the edit button state (in case we had no records before)
                self.editButtonItem.enabled = (self.records.count > 0);
            }
        }];
    }
}

// the primary search method for this app, used in viewDidLoad and from the table's refresh control
//
- (void)loadPhotos:(void (^)(void))completionHandler
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [CloudManager fetchRecordsWithType:[APLCloudManager PhotoRecordType] completionHandler:^(NSArray *records, NSError *error) {
        
        // done loading
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        self.tableView.dataSource = self;   // now that we have data, we can start populating our table
        
        if (error != nil)
        {
            if (error.code == CKErrorLimitExceeded)
            {
                // the request to the server was too large. Retry this request as a smaller batch
            }
            else if (error.code == CKErrorServerRejectedRequest)
            {
                // service or server problems
                // (may be because the record type is not defined in the schema yet or the schema was removed from CloudKit Dashboard)
                //
            }
            else if (error.code != CKErrorUnknownItem)
            {
                // note we can get CKErrorUnknownItem for the first time the app is open (no records added to that container yet, no schema defined)
                //
            }
            
            // On CKErrorServiceUnavailable or CKErrorRequestRateLimited errors:
            // the userInfo dictionary may contain a NSNumber instance that specifies the period of time in seconds after
            // which the client may retry the request.  So here we will try again.
            //
            if (error.code == CKErrorServiceUnavailable || error.code == CKErrorRequestRateLimited)
            {
                NSNumber *retryAfter = error.userInfo[CKErrorRetryAfterKey] ? : @3; // try again after 3 seconds if we don't have a retry hint
                NSLog(@"Error: %@. Recoverable, retry after %@ seconds", [error description], retryAfter);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryAfter.intValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self loadPhotos:completionHandler];
                });
            }
            else
            {
                // due to an error, no records should be shown
                _records = nil;
                [self.tableView reloadData];
            }
        }
        else
        {
            // all is good, we get back an array of CKRecords
            //NSLog(@"found %ld records", (long)records.count);
            
            _records = [records mutableCopy];
            [self.tableView reloadData];
            
            if (self.restoringSearchState)
            {
                // we are trying to restore state when our app was relaunched (UIStateRestoration)
                // so we must start our search filtering
                _restoringSearchState = NO;
                
                [self updateSearchResultsForSearchController:self.searchController];
            }
        }
        
        // edit button should be disabled if there are no records
        self.editButtonItem.enabled = (self.records.count > 0);
        
        if (completionHandler != nil)
        {
            completionHandler();    // invoke our caller's completion handler indicating we are done
        }
    }];
}


#pragma mark - Actions

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (!editing)
    {
        // reset the navigation bar if we exit edit mode
        [self updateNavigationBar];
    }
    else
    {
        // disable the add button while in edit mode
        self.addButton.enabled = NO;
    }
    
    // hide/show toolbar on edit toggle
    [self.navigationController setToolbarHidden:!editing animated:YES];
}

// called when UIRefreshControl is pulled down from our table
- (void)refresh:(id)sender
{
    self.editButtonItem.enabled = NO;    // no editing while refreshing

    [self loadPhotos:^() {
        // query completed, close out our refresh control
        [self.refreshControl endRefreshing];
        
        [self updateNavigationBar];
    }];
}

- (void)deleteAllAction:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:NSLocalizedString(@"Confirm Remove", nil)
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK Button Title", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
            // OK button action
            [CloudManager fetchLoggedInUserRecord:^(CKRecordID *loggedInUserRecord) {
            
                // find all of our photos that we own, delete only those!
                //
                __block NSMutableArray *recordIDsToDelete = [NSMutableArray arrayWithCapacity:self.records.count];
                
                for (CKRecord *record in self.records)
                {
                    CKRecordID *userRecordID = record.creatorUserRecordID;
                    if ([CloudManager isMyRecord:userRecordID])
                    {
                        // we found a deleted record we own, add it to our removal list
                        [recordIDsToDelete addObject:record.recordID];
                    }
                }
                
                // delete all operation means we exit edit mode
                [self setEditing:NO animated:YES];
                    
                if (recordIDsToDelete.count > 0)
                {
                    // remove our records
                    [CloudManager deleteRecordsWithIDs:recordIDsToDelete completionHandler:^(NSArray *deletedRecordIDs, NSError *error) {
                        
                        if (error != nil)
                        {
                            NSLog(@"An error occured in '%@': error[%ld] %@",
                                  NSStringFromSelector(_cmd), (long)error.code, error.localizedDescription);
                        }
                        
                        // proceed to remove our records from our table and refresh
                        for (CKRecordID *deletedRecordID in deletedRecordIDs)
                        {
                            for (CKRecord *record in self.records)
                            {
                                if ([record.recordID isEqual:deletedRecordID])
                                {
                                    [self.records removeObject:record];
                                    break;
                                }
                            }
                        }
                        [self.tableView reloadData];
                        
                        // disable Edit button if we have no records
                        self.editButtonItem.enabled = (self.records.count > 0);
                    }];
                }
            }];
    }];
    [alert addAction:OKAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel Button Title", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    // user tapped the scope bar, toggling between All or Near Me, so change the search criteria
    [self updateSearchResultsForSearchController:self.searchController];
}


#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController
{
    _filteredRecords = [self.records copy];
    
    NSMutableArray *scopeTitles = [NSMutableArray arrayWithArray:
                                        @[NSLocalizedString(@"All Segment Item Title", nil),
                                          NSLocalizedString(@"Owner Segment Item Title", nil),
                                          NSLocalizedString(@"Recent Segment Item Title", nil)]];
    
    if (self.currentLocation != nil)
    {
        // we have the user's location, allow for search "Near Me"
        [scopeTitles addObject:NSLocalizedString(@"Near Me Segment Item Title", nil)];
    }
    self.searchController.searchBar.scopeButtonTitles = scopeTitles;
    
    self.refreshControl.enabled = NO;   // no refreshing while filtering
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    self.refreshControl.enabled = YES;  // bring back refresh control
}


#pragma mark - UITableViewDelegate

// report the user can't delete a given CKRecord, either they are not logged in or an error was generated
//
- (void)reportLogoutDeleteError:(NSError *)error
{
    NSString *messageStr = nil;
    if (error == nil || ([[error domain] isEqualToString:CKErrorDomain] && (error.code == CKErrorNotAuthenticated)))
    {
        messageStr = NSLocalizedString(@"Removal alert detail message not logged in", nil);
    }
    else
    {
        messageStr = [NSString stringWithFormat:@"Error domain/code: %@, %ld", [error domain], (long)error.code];
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Removal alert message not logged in", nil)
                                                                   message:messageStr
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK Button Title", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
    
    self.editing = NO;  // bail out of edit mode due to error
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCellEditingStyle editingStyle = UITableViewCellEditingStyleNone;
    
    // check if the given photo is our photo, allowing us to delete it
    CKRecord *recordToCheck = (self.records)[indexPath.row];
    CKRecordID *creatorRecordID = recordToCheck.creatorUserRecordID;
    if ([CloudManager isMyRecord:creatorRecordID])
    {
        editingStyle = UITableViewCellEditingStyleDelete;
    }
    
    return editingStyle;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        CKRecord *recordToDelete = (self.records)[indexPath.row];
        
        CKRecordID *userRecordID = recordToDelete.creatorUserRecordID;
        [CloudManager fetchLoggedInUserRecord:^(CKRecordID *userRecord) {
            if (userRecord == nil)
            {
                // can't find logged in user record info, alert user we are logged out and delete is not possible
                [self reportLogoutDeleteError:nil];
            }
            else
                if ([CloudManager isMyRecord:userRecordID])
            {
                // we own this record, so we are allowed to delete it
                [CloudManager deleteRecordWithID:recordToDelete.recordID completionHandler:^(CKRecordID *recordID, NSError *error) {
                    if (error == nil)
                    {
                        // change our table view (remove the deleted record)
                        [self.records removeObject:recordToDelete];

                        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                        
                        if (self.records.count == 0)
                        {
                            // no more records left, exit edit mode
                            self.editing = NO;
                        }
                        
                        // check if there are any photos left in the list that belong to the current logged in user
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                        
                        [CloudManager fetchMyRecords:^(NSArray *myFoundRecords, NSError *error) {
                            
                            // done fetching
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                            
                            if (myFoundRecords.count == 0)
                            {
                                // none of our records were found, exit edit mode (no more deletions possible)
                                [self setEditing:NO animated:YES];
                            }
                            
                            // edit button should be disabled if there are no records or no records that belong to us
                            self.editButtonItem.enabled = (self.records.count > 0) && (myFoundRecords.count > 0);
                        }];
                    }
                }];
            }
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    APLDetailTableViewController *detailViewController = (APLDetailTableViewController *)segue.destinationViewController;
    detailViewController.delegate = self;   // so we can be notified when a record was changed by APLDetailTableViewController
    
    if ([segue.identifier isEqualToString:@"pushToDetail"])
    {
        if (self.searchController.isActive)
        {
            // remember our search controller state, so next time we become visible there's no need to start a re-filter again
            _searchControllerActiveFromPreviousView = YES;
        }
        
        // pass the CKRecord to our detail view controller
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];

        CKRecord *selectedRecord = (self.searchController.active) ? self.filteredRecords[selectedIndexPath.row] : self.records[selectedIndexPath.row];
        
        detailViewController.record = selectedRecord;
    }
}


#pragma mark - UITableViewDataSource

- (BOOL)shouldUseNoPhotosLabel
{
    BOOL shouldUseNoPhotosLabel = NO;
    NSInteger numberOfPhotos = (self.searchController.active) ? self.filteredRecords.count : self.records.count;
    if (numberOfPhotos == 0 && !self.searchController.active)
    {
        shouldUseNoPhotosLabel = YES;
    }
    return shouldUseNoPhotosLabel;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self shouldUseNoPhotosLabel])
    {
        if (![self.tableView viewWithTag:kNoPhotosLabelTag])
        {
            // add a "No Photos" label and place it within our table
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectNull];
            label.tag = kNoPhotosLabelTag;
            label.text = NSLocalizedString(@"No Photos", nil);
            label.font = [UIFont systemFontOfSize:24];
            [label sizeToFit];
            label.textColor = [UIColor lightGrayColor];
            
            [self.tableView addSubview:label];

            [label setTranslatesAutoresizingMaskIntoConstraints:NO];

            _labelConstraintForX = [NSLayoutConstraint constraintWithItem:label
                                                    attribute:NSLayoutAttributeCenterX
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:self.tableView
                                                    attribute:NSLayoutAttributeCenterX
                                                   multiplier:1.0
                                                     constant:0.0];
            _labelConstraintForY = [NSLayoutConstraint constraintWithItem:label
                                                    attribute:NSLayoutAttributeTop
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:self.tableView
                                                    attribute:NSLayoutAttributeTop
                                                   multiplier:1.0
                                                     constant:100.0];
            [self.tableView addConstraints:@[self.labelConstraintForX, self.labelConstraintForY]];
        }
    }
    else
    {
        UILabel *noRecordsLabel = (UILabel *)[self.tableView viewWithTag:kNoPhotosLabelTag];
        if (noRecordsLabel != nil)
        {
            [self.tableView removeConstraint:self.labelConstraintForX];
            [self.tableView removeConstraint:self.labelConstraintForY];
            [noRecordsLabel removeFromSuperview];
        }
    }
    
    return (self.searchController.active) ? self.filteredRecords.count : self.records.count;
}

- (void)configureCell:(UITableViewCell *)cell forRecord:(CKRecord *)record
{
    assert(cell != nil);    // we must have a cell
    
    UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:kTitleLabelTag];
    titleLabel.text = record[[APLCloudManager PhotoTitleAttribute]];
    
    // find the CKAsset for this record
    CKAsset *photoAsset = record[[APLCloudManager PhotoAssetAttribute]];
    if (photoAsset != nil)
    {
        UIImage *imageData = [UIImage imageWithContentsOfFile:[photoAsset.fileURL path]];
        UIImageView *photoView = (UIImageView *)[cell.contentView viewWithTag:kPhotoTag];
        photoView.image = imageData;
    }

    // we provide the owner of the current record in the subtite of our cell
    [CloudManager fetchUserNameFromRecordID:record.creatorUserRecordID completionHandler:^(NSString *firstName, NSString *lastName) {

        UILabel *ownerLabel = (UILabel *)[cell.contentView viewWithTag:kOwnerLabelTag];
        if (firstName == nil && lastName == nil)
        {
            ownerLabel.text = NSLocalizedString(@"Unknown User Name", nil);
        }
        else
        {
            ownerLabel.text = (lastName != nil) ? [NSString stringWithFormat:@"%@ %@", firstName, lastName] : firstName;
        }
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = (UITableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    
    CKRecord *record = (self.searchController.active) ? self.filteredRecords[indexPath.row] : self.records[indexPath.row];
    [self configureCell:cell forRecord:record];

    return cell;
}


#pragma mark - UISearchResultsUpdating

- (void)finishPhotoFilteringByTitle:(NSString *)title photos:(NSArray *)photosToFilter
{
    NSArray *newlyFilteredRecords = [photosToFilter copy];
    
    // done fetching
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // filter list further down by photo title
    if (title.length > 0)
    {
        // if we have search text, filter down the results further
        NSPredicate *titleSearchPredicate =
            [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", [APLCloudManager PhotoTitleAttribute], title]; // [cd] = case insensitive
        
        newlyFilteredRecords = [photosToFilter filteredArrayUsingPredicate:titleSearchPredicate];
    }
    
    self.filteredRecords = newlyFilteredRecords;
    [self.tableView reloadData];
}

// Called when the search bar's text or scope has changed or when the search bar becomes first responder.
//
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchText = searchController.searchBar.text;
    
    if (searchController.isActive)
    {
        if (self.searchControllerActiveFromPreviousView)
        {
            // search controller was active at the time we navigated to our detail view controller
            // no need to start a re-filter again
            //
            _searchControllerActiveFromPreviousView = NO;
            return;
        }
    
        // filtering works only if we have records to filter
        //
        if (self.records != nil && self.records.count > 0)
        {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            
            switch (self.searchController.searchBar.selectedScopeButtonIndex)
            {
                case kAllScope:
                {
                    // search for all photos
                    
                    // just filter what we currently have by kPhotoTitle attribute
                    [self finishPhotoFilteringByTitle:searchText photos:self.records];
                    break;
                }
                    
                case kMineScope:
                {
                    // search for photos by owner (me)
                    //
                    [CloudManager fetchMyRecords:^(NSArray *foundRecords, NSError *error) {
                    
                        // done fetching, filter the photos further by photo title
                        [self finishPhotoFilteringByTitle:searchText photos:foundRecords];
                    }];
                    
                    break;
                }
                    
                case kRecentScope:
                {
                    // find photos created in the last 5 days
                    //
                    [CloudManager fetchRecentRecords:5 completionHandler:^(NSArray *foundRecords, NSError *error) {
                        
                        // done fetching, filter the photos further by kPhotoTitle attribute
                        [self finishPhotoFilteringByTitle:searchText photos:foundRecords];
                    }];
                    
                    break;
                }
                    
                case kNearMeScope:
                {
                    // we have tracked the user's location, and the user wants to search for photos for "near us"
                    
                    // for this scope to work, we "should" have the user's location by now
                    assert(self.currentLocation != nil);
                    
                    [CloudManager fetchRecordsNearLocation:self.currentLocation completionHandler:^(NSArray *foundRecords, NSError *error) {
                        
                        // done fetching, filter the photos further by kPhotoTitle attribute
                        [self finishPhotoFilteringByTitle:searchText photos:foundRecords];
                    }];
                    
                    break;
                }
            }
        }
    }
}


#pragma mark - DetailViewControllerDelegate

// we are being notified by APLDetailViewController, that a record was added
- (void)detailViewController:(APLDetailTableViewController *)viewController didAddCloudRecord:(CKRecord *)record
{
    // add the record to the table
    [self updateTableWithRecordID:record.recordID reason:CKQueryNotificationReasonRecordCreated];
}

// we are being notified by APLDetailViewController, that a record was changed
- (void)detailViewController:(APLDetailTableViewController *)viewController didChangeCloudRecord:(CKRecord *)record
{
    // update the record in the table
    [self updateTableWithRecordID:record.recordID reason:CKQueryNotificationReasonRecordUpdated];
}

// we are being notified by APLDetailViewController, that a record was deleted
- (void)detailViewController:(APLDetailTableViewController *)viewController didDeleteCloudRecord:(CKRecord *)record
{
    [self updateTableWithRecordID:record.recordID reason:CKQueryNotificationReasonRecordDeleted];
}


#pragma mark - Push Notifications

// called by our AppDelegate to handle a specific push notification of a specifc CKRecordID,
// that record could have beed added, deleted or updated.  This is done silently.
//
- (void)handlePushWithRecordID:(CKRecordID *)recordID reason:(CKQueryNotificationReason)reason
{
    // a record has come in that was added, deleted or updated
    //
    // update just the table cell this CKRecord is associated with,
    // instead of just doing an entire table re-fetch, let's be efficient and just apply the update for the record in question
    //
    [self updateTableWithRecordID:recordID reason:reason];
}


#pragma mark - Account Change Notification

// called when we receive notification from our App Delegate that the user logged in our out
- (void)iCloudAccountAvailabilityChanged
{
    // the user signs out of iCloud (such as by turning off Documents & Data in Settings),
    // or
    // has signed back in:
    // so we need to refresh our UI, this will update our UI to reflect user login
    //
    [CloudManager updateUserLogin:^() {
        [self updateNavigationBar];
    }];
}


#pragma mark - Core Location

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    _currentLocation = [locations objectAtIndex:0];
    [self.locationManager stopUpdatingLocation];    // we found the user's location, so stop tracking
}


#pragma mark - UIStateRestoration

/* we restore several items for state restoration:
 1) Search controller's active state,
 2) search text,
 3) first responder status
*/
static NSString *SearchControllerIsActiveKey = @"SearchControllerIsActiveKey";
static NSString *SearchBarTextKey = @"SearchBarTextKey";
static NSString *SearchBarIsFirstResponderKey = @"SearchBarIsFirstResponderKey";
static NSString *SearchBarScopeKey = @"SearchScopeBarScopeKey";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    // encode the search controller's active state
    BOOL searchDisplayControllerIsActive = self.searchController.isActive;
    [coder encodeBool:searchDisplayControllerIsActive forKey:SearchControllerIsActiveKey];
    
    // encode the first responser status
    if (searchDisplayControllerIsActive)
    {
        [coder encodeBool:[self.searchController.searchBar isFirstResponder] forKey:SearchBarIsFirstResponderKey];
    }
    
    // encode the search bar text
    [coder encodeObject:self.searchController.searchBar.text forKey:SearchBarTextKey];
    
    // encode the search bar scope button index
    [coder encodeInteger:self.searchController.searchBar.selectedScopeButtonIndex forKey:SearchBarScopeKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    // restore the active state:
    // we can't make the searchController active here since it's not part of the view
    // hierarchy yet, instead we do it in viewWillAppear
    //
    _searchControllerWasActive = [coder decodeBoolForKey:SearchControllerIsActiveKey];
    
    // restore the first responder status:
    // we can't make the searchController first responder here since it's not part of the view
    // hierarchy yet, instead we do it in viewWillAppear
    //
    _searchControllerSearchFieldWasFirstResponder = [coder decodeBoolForKey:SearchBarIsFirstResponderKey];
    
    // restore the text in the search field
    _searchControllerText = [coder decodeObjectForKey:SearchBarTextKey];
    
    // restore the scope button index in the search field
    _searchControllerScopeIndex = [coder decodeIntegerForKey:SearchBarScopeKey];
}

@end

