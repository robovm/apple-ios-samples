/*
    File:       PhotoGalleryViewController.h

    Contains:   Shows a list of all the photos in a gallery.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "PhotoGalleryViewController.h"

#import "PhotoCell.h"

#import "PhotoDetailViewController.h"

#import "PhotoGallery.h"
#import "Photo.h"

#import "QLogViewer.h"
#import "QLog.h"

@interface PhotoGalleryViewController () <NSFetchedResultsControllerDelegate>

// private properties

@property (nonatomic, retain, readwrite) UIBarButtonItem *              stopBarButtonItem;
@property (nonatomic, retain, readwrite) UIBarButtonItem *              refreshBarButtonItem;
@property (nonatomic, retain, readwrite) UIBarButtonItem *              fixedBarButtonItem;
@property (nonatomic, retain, readwrite) UIBarButtonItem *              flexBarButtonItem;
@property (nonatomic, retain, readwrite) UIBarButtonItem *              statusBarButtonItem;

@property (nonatomic, retain, readwrite) NSFetchedResultsController *   fetcher;

@property (nonatomic, copy,   readwrite) NSDateFormatter *              dateFormatter;

// forward declarations

- (void)setupStatusLabel;
- (void)setupSyncBarButtonItem;

@end

@implementation PhotoGalleryViewController

- (id)initWithPhotoGallery:(PhotoGallery *)photoGallery
    // See comment in header.
{
    // photoGallery may be nil
    self = [super initWithNibName:nil bundle:nil];
    if (self != nil) {
        UILabel *   statusLabel;

        self->_photoGallery = [photoGallery retain];
        
        self.title = @"Photos";

        // Set up a raft of bar button items.
        
        self->_stopBarButtonItem    = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopAction:)];
        self->_refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshAction:)];
        self->_fixedBarButtonItem   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        self->_fixedBarButtonItem.width = 25.0f;
        self->_flexBarButtonItem    = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        statusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 250.0f, 32.0f)] autorelease];
        assert(statusLabel != nil);
        
        statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        statusLabel.textColor        = [UIColor whiteColor];
        statusLabel.textAlignment    = UITextAlignmentCenter;
        statusLabel.backgroundColor  = [UIColor clearColor];
        statusLabel.font             = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];

        self->_statusBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:statusLabel];

        // Add an observer to the QLog's showViewer property to update whether we show our 
        // "Log" button in the left bar button position of the navigation bar.
        
        [[QLog log] addObserver:self forKeyPath:@"showViewer" options:NSKeyValueObservingOptionInitial context:NULL];
        
        // Add an observer for our own photoGallery property, so that we can adjust our UI 
        // when it changes.  Note that we set NSKeyValueObservingOptionPrior so that we 
        // get called before /and/ after the change, allowing us to shut down our UI before 
        // the change and bring it up again afterwards.
        
        [self addObserver:self forKeyPath:@"photoGallery" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionPrior context:&self->_photoGallery];
    }
    return self;
}

- (void)dealloc
{
    // There's no intrinsic reason why this class shouldn't support -dealloc, 
    // but in this application the following code never runs, and so is untested, 
    // and hence has a leading assert.
    
    assert(NO);
    
    // Remove all our KVO observers.
    
    if (self->_photoGallery != nil) {
        [self->_photoGallery removeObserver:self forKeyPath:@"syncing"];
        [self->_photoGallery removeObserver:self forKeyPath:@"syncStatus"];
        [self->_photoGallery removeObserver:self forKeyPath:@"standardDateFormatter"];
    }
    [self removeObserver:self forKeyPath:@"photoGallery"];
    [[QLog log] removeObserver:self forKeyPath:@"showViewer"];

    // Release our ivars.
    
    [self->_stopBarButtonItem release];
    [self->_refreshBarButtonItem release];
    [self->_fixedBarButtonItem release];
    [self->_flexBarButtonItem release];
    [self->_statusBarButtonItem release];

    [self->_photoGallery release];
    if (self->_fetcher != nil) {
        self->_fetcher.delegate = nil;
        [self->_fetcher release];
    }
    [self->_dateFormatter release];

    [super dealloc];
}

- (void)startFetcher
    // Starts the fetch results controller that provides the data for our table.
{
    BOOL                            success;
    NSError *                       error;
    NSFetchRequest *                fetchRequest;
    NSSortDescriptor *              sortDescriptor;

    assert(self.photoGallery != nil);
    assert(self.photoGallery.managedObjectContext != nil);
    
    sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
    assert(sortDescriptor != nil);
    
    fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    assert(fetchRequest != nil);

    [fetchRequest setEntity:self.photoGallery.photoEntity];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    assert(self.fetcher == nil);
    self.fetcher = [[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.photoGallery.managedObjectContext sectionNameKeyPath:nil cacheName:nil] autorelease];
    assert(self.fetcher != nil);
    
    self.fetcher.delegate = self;
    
    success = [self.fetcher performFetch:&error];
    if ( ! success ) {
        [[QLog log] logWithFormat:@"viewer fetch failed %@", error];
    }
}

- (void)reloadTable
    // Forces a reload of the table if the view is loaded.
{
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->_stopBarButtonItem) {
    
        // Set up the Refresh/Stop button in the toolbar based on the syncing state of 
        // the photo gallery.
    
        assert([keyPath isEqual:@"syncing"]);
        assert(object == self.photoGallery);
        [self setupSyncBarButtonItem];

    } else if (context == &self->_statusBarButtonItem) {
    
        // Set the status label in the toolbar based on the syncing status from the 
        // the photo gallery.
    
        assert([keyPath isEqual:@"syncStatus"]);
        assert(object == self.photoGallery);
        [self setupStatusLabel];

    } else if (context == &self->_photoGallery) {
        assert([keyPath isEqual:@"photoGallery"]);
        assert(object == self);
        
        if ( (change != nil) && [[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue] ) {
            if (self.photoGallery != nil) {
                
                // The gallery is about to go away.  Remove our observers and shut down the fetched results 
                // controller that provides the data for our table.
            
                [self.photoGallery removeObserver:self forKeyPath:@"syncing"];
                [self.photoGallery removeObserver:self forKeyPath:@"syncStatus"];
                [self.photoGallery removeObserver:self forKeyPath:@"standardDateFormatter"];

                self.fetcher.delegate = nil;
                self.fetcher = nil;
            }
        } else {
            if (self.photoGallery == nil) {
            
                // There's no new gallery.  We call -setupStatusLabel and -setupSyncBarButtonItem directly, 
                // and these methods configure us to display the placeholder UI.
                
                [self setupStatusLabel];
                [self setupSyncBarButtonItem];
            } else {
                // Install a bunch of KVO observers to track various chunks of state and update our UI 
                // accordingly.  Note that these have NSKeyValueObservingOptionInitial set, so our 
                // -observeValueForKeyPath:xxx method is called immediately to set up the initial 
                // state.

                [self.photoGallery addObserver:self forKeyPath:@"syncing"               options:NSKeyValueObservingOptionInitial context:&self->_stopBarButtonItem];
                [self.photoGallery addObserver:self forKeyPath:@"syncStatus"            options:NSKeyValueObservingOptionInitial context:&self->_statusBarButtonItem];
                [self.photoGallery addObserver:self forKeyPath:@"standardDateFormatter" options:NSKeyValueObservingOptionInitial context:&self->_dateFormatter];
            
                // Set up the fetched results controller that provides the data for our table.

                [self startFetcher];
            }

            // And reload the table to account for any possible change.

            [self reloadTable];
        }
    } else if (context == &self->_dateFormatter) {
    
        // Called when the standardDateFormatter property of the gallery changes (which typically 
        // happens when the user changes their locale or time zone settings).  We apply this change 
        // to ourselves and then reload the table so that all our cells pick up the new formatter.
    
        assert([keyPath isEqual:@"standardDateFormatter"]);
        assert(object == self.photoGallery);
        self.dateFormatter = self.photoGallery.standardDateFormatter;
        [self reloadTable];

    } else if ( (context == NULL) && [keyPath isEqual:@"showViewer"] ) {
    
        // Called when the showViewer property of QLog changes (typically because the user has 
        // toggled the setting in the Settings application).  We set the left bar button position 
        // of our navigation item accordingly.
    
        assert(object == [QLog log]);
        if ( [QLog log].showViewer ) {
            self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Log" style:UIBarButtonItemStyleBordered target:self action:@selector(showLogAction:)] autorelease];
            assert(self.navigationItem.leftBarButtonItem != nil);
        } else {
            self.navigationItem.leftBarButtonItem = nil;
        }
    } else if (NO) {   // Disabled because the super class does nothing useful with it.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark * View controller stuff

@synthesize stopBarButtonItem    = _stopBarButtonItem;
@synthesize refreshBarButtonItem = _refreshBarButtonItem;
@synthesize fixedBarButtonItem   = _fixedBarButtonItem;
@synthesize flexBarButtonItem    = _flexBarButtonItem;
@synthesize statusBarButtonItem  = _statusBarButtonItem;

@synthesize photoGallery         = _photoGallery;
@synthesize fetcher              = _fetcher;
@synthesize dateFormatter        = _dateFormatter;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Configure the table view itself.
    
    self.tableView.rowHeight = kThumbnailSize + 3.0f;

    // If our view got unloaded, and hence our fetcher got nixed, we reestablish it 
    // on the reload.
    
    if ( (self.photoGallery != nil) && (self.fetcher == nil) ) {
        [self startFetcher];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // There no point having a fetched results controller around if the view is unloaded.
    
    self.fetcher.delegate = nil;
    self.fetcher = nil;
}

#pragma mark * Table view callbacks

- (BOOL)hasNoPhotos
    // Returns YES if there are no photos to display.  The table view callbacks use this extensively 
    // to determine whether to show a placeholder ("No photos") or real content.
{
    BOOL        result;
    NSArray *   sections;
    NSUInteger  sectionCount;
    
    result = YES;
    if (self.fetcher != nil) {
        sections = [self.fetcher sections];
        sectionCount = [sections count];
        if (sectionCount > 0) {
            if ( (sectionCount > 1) || ([[sections objectAtIndex:0] numberOfObjects] != 0) ) {
                result = NO;
            }
        }
    }
    
    return result;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    NSInteger   result;
    
    assert(tv == self.tableView);
    #pragma unused(tv)
    if ( [self hasNoPhotos] ) {
        result = 1;                                 // if there's no photos, there's 1 section with 1 row that is the placeholder UI
    } else {
        result = [[self.fetcher sections] count];   // if there's photos, base this off the fetcher results controller
    }
    return result;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    #pragma unused(tv)
    #pragma unused(section)
    NSInteger   result;

    assert(tv == self.tableView);

    if ( [self hasNoPhotos] ) {
        result = 1;                                 // if there's no photos, there's 1 section with 1 row that is the placeholder UI
    } else {
        NSArray *   sections;                       // if there's photos, base this off the fetcher results controller

        sections = [self.fetcher sections];
        assert(sections != nil);
        assert(section >= 0);
        assert( (NSUInteger) section < [sections count] );
        result = [[sections objectAtIndex:section] numberOfObjects];
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)
    UITableViewCell *   result;

    assert(tv == self.tableView);
    assert(indexPath != NULL);

    if ( [self hasNoPhotos] ) {
        
        // There are no photos to display; return a cell that simple says "No photos".
        
        result = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
        if (result == nil) {
            result = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"] autorelease];
            assert(result != nil);
            
            result.textLabel.text = @"No photos";
            result.textLabel.textColor = [UIColor darkGrayColor];
            result.textLabel.textAlignment = UITextAlignmentCenter;
        }
        result.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        PhotoCell *     cell;
        Photo *         photo;

        // Return a cell that displays the appropriate photo.  Note that we just tell 
        // the cell what photo to display, and it takes care of displaying the right 
        // stuff (via the miracle of KVO).

        photo = [self.fetcher objectAtIndexPath:indexPath];
        assert([photo isKindOfClass:[Photo class]]);
        
        cell = (PhotoCell *) [self.tableView dequeueReusableCellWithIdentifier:@"PhotoCell"];
        if (cell != nil) {
            assert([cell isKindOfClass:[PhotoCell class]]);
        } else {
            cell = [[[PhotoCell alloc] initWithReuseIdentifier:@"PhotoCell"] autorelease];
            assert(cell != nil);
            
            assert(cell.selectionStyle == UITableViewCellSelectionStyleBlue);
            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.photo = photo;
        cell.dateFormatter = self.dateFormatter;
        
        result = cell;
    }

    return result;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)

    assert(tv == self.tableView);
    assert(indexPath != NULL);
    // assert(indexPath.section == 0);
    // assert(indexPath.row < ?);

    if ( [self hasNoPhotos] ) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        Photo *                         photo;
        PhotoDetailViewController *     vc;

        // Push a photo detail view controller to display the bigger version 
        // of the photo.

        photo = [self.fetcher objectAtIndexPath:indexPath];
        assert([photo isKindOfClass:[Photo class]]);
        
        vc = [[[PhotoDetailViewController alloc] initWithPhoto:photo photoGallery:self.photoGallery] autorelease];
        assert(vc != nil);
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark * Fetched results controller callbacks

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
    // A delegate callback called by the fetched results controller when its content 
    // changes.  If anything interesting happens (that is, an insert, delete or move), we 
    // respond by reloading the entire table.  This is rather a heavy-handed approach, but 
    // I found it difficult to correctly handle the updates.  Also, the insert, delete and 
    // move aren't on the critical performance path (which is scrolling through the list 
    // loading thumbnails), so I can afford to keep it simple.
{
    assert(controller == self.fetcher);
    #pragma unused(controller)
    #pragma unused(anObject)
    #pragma unused(indexPath)
    #pragma unused(newIndexPath)

    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self reloadTable];
        } break;
        case NSFetchedResultsChangeDelete: {
            [self reloadTable];
        } break;
        case NSFetchedResultsChangeMove: {
            [self reloadTable];
        } break;
        case NSFetchedResultsChangeUpdate: {
            // do nothing
        } break;
        default: {
            assert(NO);
        } break;
    }
}

#pragma mark * UI wrangling

- (void)setupStatusLabel
    // Set the status label in the toolbar based on the syncing status from the 
    // the photo gallery.
{
    UILabel *   statusLabel;
    
    assert(self.statusBarButtonItem != nil);

    statusLabel = (UILabel *) self.statusBarButtonItem.customView;
    assert([statusLabel isKindOfClass:[UILabel class]]);

    if (self.photoGallery == nil) {
        statusLabel.text = @"Tap Setup to configure";
    } else {
        statusLabel.text = self.photoGallery.syncStatus;
    }
}

- (void)setupSyncBarButtonItem
    // Set up the Refresh/Stop button in the toolbar based on the syncing state of 
    // the photo gallery.
{
    assert(self.fixedBarButtonItem != nil);
    assert(self.statusBarButtonItem != nil);
    assert(self.flexBarButtonItem != nil);
    assert(self.stopBarButtonItem != nil);

    if ( (self.photoGallery != nil) && self.photoGallery.isSyncing ) {
        self.toolbarItems = [NSArray arrayWithObjects:self.fixedBarButtonItem, self.statusBarButtonItem, self.flexBarButtonItem, self.stopBarButtonItem, nil];
    } else {
        self.refreshBarButtonItem.enabled = (self.photoGallery != nil);
        self.toolbarItems = [NSArray arrayWithObjects:self.fixedBarButtonItem, self.statusBarButtonItem, self.flexBarButtonItem, self.refreshBarButtonItem, nil];
    }
}

#pragma mark * Actions

- (void)showLogAction:(id)sender
    // Called when the user taps the Log button.  It just presents the log 
    // view controller.
{
    #pragma unused(sender)
    QLogViewer *            vc;
    
    vc = [[[QLogViewer alloc] init] autorelease];
    assert(vc != nil);
    
    [vc presentModallyOn:self animated:YES];
}

- (IBAction)stopAction:(id)sender
    // Called when the user taps the Stop button.  It just passes the command 
    // on to the photo gallery.
{
    #pragma unused(sender)
    [self.photoGallery stopSync];
}

- (IBAction)refreshAction:(id)sender
    // Called when the user taps the Refresh button.  It just passes the command 
    // on to the photo gallery.
{
    #pragma unused(sender)
    [self.photoGallery startSync];
}

@end
