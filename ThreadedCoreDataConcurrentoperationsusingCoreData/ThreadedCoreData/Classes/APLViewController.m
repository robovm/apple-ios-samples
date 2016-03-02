/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 View controller for displaying the earthquake list.
 */

#import "APLViewController.h"
#import "APLEarthQuakeSource.h"

#import "APLEarthquake.h"
#import "APLEarthquakeTableViewCell.h"

#import "APLCoreDataStackManager.h"

@import CoreData;
@import MapKit;   // for CLLocationCoordinate2D and MKPlacemark


@interface APLViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) APLEarthQuakeSource *earthQuakeSource;

@property (assign) id localChangedObserver;

@property (nonatomic, strong) UIAlertController *alert;

@end


#pragma mark -

@implementation APLViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    _earthQuakeSource = [[APLEarthQuakeSource alloc] init];
    
    // listen for incoming earthquakes from our data source using KVO
    [self.earthQuakeSource addObserver:self forKeyPath:@"earthquakes" options:0 context:nil];
    
    // listen for errors reported by our data source using KVO, so we can report it in our own way
    [self.earthQuakeSource addObserver:self forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:nil];
    
    // Our NSNotification callback when the user changes the locale (region format) in Settings, so we are notified here to
    // update the date format in the table view cells
    //
    _localChangedObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:NSCurrentLocaleDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *notification) {
            [self.tableView reloadData];
        }];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.earthQuakeSource startEarthQuakeLookup];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.localChangedObserver];
}


#pragma mark - UITableViewDelegate

/**
 * The number of rows is equal to the number of earthquakes in the array.
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    NSInteger numberOfRows = 0;
    
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
        numberOfRows = [sectionInfo numberOfObjects];
    }
    
    return numberOfRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return self.fetchedResultsController.sections.count;
}

/**
 * Return the proper table view cell for each earthquake
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *kEarthquakeCellID = @"EarthquakeCellID";
  	APLEarthquakeTableViewCell *cell = (APLEarthquakeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kEarthquakeCellID];

    // Get the specific earthquake for this row.
    APLEarthquake *earthquake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [cell configureWithEarthquake:earthquake];
    
	return cell;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    APLEarthQuakeSource *earthQuakeSource = object;
    
    if ([keyPath isEqualToString:@"earthquakes"])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [self.tableView reloadData];
        });
    }
    else if ([keyPath isEqualToString:@"error"])
    {
        /* Handle errors in the download by showing an alert to the user. This is a very simple way of handling the error, partly because this application does not have any offline functionality for the user. Most real applications should handle the error in a less obtrusive way and provide offline functionality to the user.
            */
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            NSError *error = earthQuakeSource.error;
        
            NSString *errorMessage = error.localizedDescription;
            NSString *alertTitle = NSLocalizedString(@"Error", @"Title for alert displayed when download or parse error occurs.");
            NSString *okTitle = NSLocalizedString(@"OK", @"OK Title for alert displayed when download or parse error occurs.");
            
            _alert = [UIAlertController alertControllerWithTitle:alertTitle message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
                //..
            }];
            [self.alert addAction:action];
            
            if (self.presentedViewController == nil) {
                [self presentViewController:self.alert animated:YES completion:^ {
                    //..
                }];
            }
        });
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - NSFetchedResultsController

// called after fetched results controller received a content change notification
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    [self.tableView reloadData];
}

- (NSFetchedResultsController *)fetchedResultsController {

    // Set up the fetched results controller if needed.
    if (_fetchedResultsController == nil) {
        
        // Create the fetch request for the entity.
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity =
            [NSEntityDescription entityForName:@"APLEarthquake"
                        inManagedObjectContext:[[APLCoreDataStackManager sharedManager] managedObjectContext]];
        [fetchRequest setEntity:entity];
        
        // sort by date
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        NSFetchedResultsController *aFetchedResultsController =
        [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                            managedObjectContext:[[APLCoreDataStackManager sharedManager] managedObjectContext]
                                              sectionNameKeyPath:nil
                                                       cacheName:nil];
        self.fetchedResultsController = aFetchedResultsController;
        
        self.fetchedResultsController.delegate = self;
        
        NSError *error = nil;
        
        if (![self.fetchedResultsController performFetch:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate.
            // You should not use this function in a shipping application, although it may be useful
            // during development. If it is not possible to recover from the error, display an alert
            // panel that instructs the user to quit the application by pressing the Home button.
            //
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    return _fetchedResultsController;
}

@end

