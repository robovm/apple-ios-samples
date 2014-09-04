/*
    File:       PhotoGallery.m

    Contains:   A model object that represents a gallery of photos on the network.

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

#import "PhotoGallery.h"

#import "Photo.h"

#import "PhotoGalleryContext.h"

#import "NetworkManager.h"

#import "RecursiveDeleteOperation.h"
#import "RetryingHTTPOperation.h"
#import "GalleryParserOperation.h"

#import "Logging.h"

@interface PhotoGallery ()

// read/write variants of public properties

@property (nonatomic, retain, readwrite) NSEntityDescription *      photoEntity;

// private properties

@property (nonatomic, assign, readonly ) NSUInteger                 sequenceNumber;
@property (nonatomic, retain, readwrite) PhotoGalleryContext *      galleryContext;

@property (nonatomic, copy,   readonly ) NSString *                 galleryCachePath;
@property (nonatomic, retain, readwrite) NSTimer *                  saveTimer;

@property (nonatomic, assign, readwrite) PhotoGallerySyncState      syncState;
@property (nonatomic, retain, readwrite) RetryingHTTPOperation *    getOperation;
@property (nonatomic, retain, readwrite) GalleryParserOperation *   parserOperation;
@property (nonatomic, copy,   readwrite) NSDate *                   lastSyncDate;
@property (nonatomic, copy,   readwrite) NSError *                  lastSyncError;

// forward declarations

- (void)startParserOperationWithData:(NSData *)data;
- (void)commitParserResults:(NSArray *)latestResults;

@end

@implementation PhotoGallery

// These strings define the format of our gallery cache.  First up, kGalleryNameTemplate 
// and kGalleryExtension specify the name of the gallery cache directory itself.

static NSString * kGalleryNameTemplate = @"Gallery%.9f.%@";
static NSString * kGalleryExtension    = @"gallery";

// Then, within each gallery cache directory, there are the following items:
//
// o kInfoFileName is the name of a plist file within the gallery cache.  If this is missing, 
//   the gallery cache has been abandoned (and can be removed at the next startup time).
//
// o kDatabaseFileName is the name of the Core Data file that holds the Photo and Thumbnail 
//   model objects.
//
// o kPhotosDirectoryName is the name of the directory containing the actual photo files.
//   Note that this is shared with PhotoGalleryContext, which is why it's not "static".

static NSString * kInfoFileName        = @"GalleryInfo.plist";
static NSString * kDatabaseFileName    = @"Gallery.db";
       NSString * kPhotosDirectoryName = @"Photos";

// The gallery info file (kInfoFileName) contains a dictionary with just one property 
// currently defined, kInfoFileName, which is the URL string of the gallery's XML data.

static NSString * kGalleryInfoKeyGalleryURLString = @"gallerURLString";

+ (NSString *)cachesDirectoryPath
    // Returns the path to the caches directory.  This is a class method because it's 
    // used by +applicationStartup.
{
    NSString *      result;
    NSArray *       paths;

    result = nil;
    paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if ( (paths != nil) && ([paths count] != 0) ) {
        assert([[paths objectAtIndex:0] isKindOfClass:[NSString class]]);
        result = [paths objectAtIndex:0];
    }
    return result;
}

+ (void)abandonGalleryCacheAtPath:(NSString *)galleryCachePath
{
    (void) [[NSFileManager defaultManager] removeItemAtPath:[galleryCachePath stringByAppendingPathComponent:kInfoFileName] error:NULL];
}

+ (void)applicationStartup
    // See comment in header.
{
    NSUserDefaults *    userDefaults;
    NSFileManager *     fileManager;
    BOOL                clearAllCaches;
    NSString *          cachesDirectoryPath;
    NSArray *           potentialGalleryCacheNames;
    NSMutableArray *    deletableGalleryCachePaths;
    NSMutableArray *    liveGalleryCachePathsAndDates;

    fileManager = [NSFileManager defaultManager];
    assert(fileManager != nil);

    userDefaults = [NSUserDefaults standardUserDefaults];
    assert(userDefaults != nil);
    
    cachesDirectoryPath = [self cachesDirectoryPath];
    assert(cachesDirectoryPath != nil);

    // See if we've been asked to nuke all gallery caches.
    
    clearAllCaches = [userDefaults boolForKey:@"galleryClearCache"];
    if (clearAllCaches) {
        [[QLog log] logWithFormat:@"gallery clear cache"];
        
        [userDefaults removeObjectForKey:@"galleryClearCache"];
        [userDefaults synchronize];
    }

    // Walk the list of gallery caches looking for abandoned ones (or, if we're 
    // clearing all caches, do them all).  Add the targeted gallery caches 
    // to our list of things to delete.  Also, for any galleries that remain, 
    // put the path and the mod date in a list so that we can then find the 
    // oldest galleries and delete them.
    
    deletableGalleryCachePaths = [NSMutableArray array];
    assert(deletableGalleryCachePaths != nil);
    
    potentialGalleryCacheNames = [fileManager contentsOfDirectoryAtPath:cachesDirectoryPath error:NULL];
    assert(potentialGalleryCacheNames != nil);
    
    liveGalleryCachePathsAndDates = [NSMutableArray array];
    assert(liveGalleryCachePathsAndDates != nil);
    
    for (NSString * galleryCacheName in potentialGalleryCacheNames) {
        if ([galleryCacheName hasSuffix:kGalleryExtension]) {
            NSString *      galleryCachePath;
            NSString *      galleryInfoFilePath;
            NSString *      galleryDatabaseFilePath;

            galleryCachePath = [cachesDirectoryPath stringByAppendingPathComponent:galleryCacheName];
            assert(galleryCachePath != nil);

            galleryInfoFilePath = [galleryCachePath stringByAppendingPathComponent:kInfoFileName];
            assert(galleryInfoFilePath != nil);

            galleryDatabaseFilePath = [galleryCachePath stringByAppendingPathComponent:kDatabaseFileName];
            assert(galleryDatabaseFilePath != nil);

            if (clearAllCaches) {
                [[QLog log] logWithFormat:@"gallery clear '%@'", galleryCacheName];
                (void) [fileManager removeItemAtPath:galleryInfoFilePath error:NULL];
                [deletableGalleryCachePaths addObject:galleryCachePath];
            } else if ( ! [fileManager fileExistsAtPath:galleryInfoFilePath]) {
                [[QLog log] logWithFormat:@"gallery delete abandoned '%@'", galleryCacheName];
                [deletableGalleryCachePaths addObject:galleryCachePath];
            } else {
                NSDate *    modDate;

                // This gallery cache isn't abandoned.  Get the modification date of its database.  If 
                // that fails, the gallery cache is toast, so just add it to the to-delete list.  
                // If that succeeds, add a dictionary containing the gallery cache path and the 
                // mod date to the list of live gallery caches.

                modDate = [[fileManager attributesOfItemAtPath:galleryDatabaseFilePath error:NULL] objectForKey:NSFileModificationDate];
                if (modDate == nil) {
                    [[QLog log] logWithFormat:@"gallery delete invalid '%@'", galleryCacheName];
                    [deletableGalleryCachePaths addObject:galleryCachePath];
                } else {
                    assert([modDate isKindOfClass:[NSDate class]]);
                    [liveGalleryCachePathsAndDates addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        galleryCachePath,   @"path", 
                        modDate,            @"modDate", 
                        nil
                    ]];
                }
            }
        }
    }
    
    // See if we've exceeded our gallery cache limit, in which case we keep abandoning the oldest 
    // gallery cache until we're under that limit.
    
    [liveGalleryCachePathsAndDates sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"modDate" ascending:YES] autorelease]]];
    while ( [liveGalleryCachePathsAndDates count] > 3 ) {
        NSString *  path;
        
        path = [[liveGalleryCachePathsAndDates objectAtIndex:0] objectForKey:@"path"];
        assert([path isKindOfClass:[NSString class]]);

        [[QLog log] logWithFormat:@"gallery abandon and delete '%@'", [path lastPathComponent]];

        [self abandonGalleryCacheAtPath:path];
        [deletableGalleryCachePaths addObject:path];
        
        [liveGalleryCachePathsAndDates removeObjectAtIndex:0];
    }
    
    // Start an operation to delete the targeted gallery caches.  This happens on a 
    // thread so that it doesn't prevent the app starting up.  The app will 
    // ignore these gallery caches anyway, because we removed their gallery info files. 
    // Also, we don't monitor this operation for successful completion.  It 
    // just does its stuff and then goes away.  That means that we effectively 
    // leak the operation queue.  Not a big deal.  It also means that, if the 
    // app quits before the operation is done, it just gets killed.  That's 
    // OK too; the delete will pick up where it left off when the app is next 
    // relaunched.
    
    if ( [deletableGalleryCachePaths count] != 0 ) {
        static NSOperationQueue *   sGalleryDeleteQueue;
        RecursiveDeleteOperation *  op;
        
        sGalleryDeleteQueue = [[NSOperationQueue alloc] init];
        assert(sGalleryDeleteQueue != nil);
        
        op = [[[RecursiveDeleteOperation alloc] initWithPaths:deletableGalleryCachePaths] autorelease];
        assert(op != nil);
        
        if ( [op respondsToSelector:@selector(setThreadPriority:)] ) {
            [op setThreadPriority:0.1];
        }
        
        [sGalleryDeleteQueue addOperation:op];
    }
}

- (id)initWithGalleryURLString:(NSString *)galleryURLString
{
    assert(galleryURLString != nil);
    
    // The initialisation method is very simple.  All of the heavy lifting is done 
    // in -start.
    
    self = [super init];
    if (self != nil) {
        static NSUInteger sNextGallerySequenceNumber;
        
        self->_galleryURLString = [galleryURLString copy];
        self->_sequenceNumber = sNextGallerySequenceNumber;
        sNextGallerySequenceNumber += 1;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [[QLog log] logWithFormat:@"gallery %zu is %@", (size_t) self->_sequenceNumber, galleryURLString];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];

    [self->_galleryURLString release];

    // We should have been stopped before being released, so these properties 
    // should be nil by the time -dealloc is called.
    assert(self->_galleryContext == nil);
    assert(self->_photoEntity == nil);
    assert(self->_saveTimer == nil);

    [self->_lastSyncDate release];
    [self->_lastSyncError release];
    [self->_standardDateFormatter release];

    // We should have been stopped before being released, so these properties 
    // should be nil by the time -dealloc is called.
    assert(self->_getOperation == nil);
    assert(self->_parserOperation == nil);

    [super dealloc];
}

@synthesize galleryURLString = _galleryURLString;
@synthesize sequenceNumber   = _sequenceNumber;

- (void)didBecomeActive:(NSNotification *)note
{
    #pragma unused(note)
    
    // Having the ability to sync on activate makes it easy to test various cases where 
    // you want to force a sync in a weird context (like when the PhotoDetailViewController 
    // is up).
    
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"gallerySyncOnActivate"] ) {
        if (self.galleryContext != nil) {
            [self startSync];
        }
    }
}

#pragma mark * Core Data wrangling

@synthesize galleryContext = _galleryContext;

+ (NSSet *)keyPathsForValuesAffectingManagedObjectContext
{
    return [NSSet setWithObject:@"galleryContext"];
}

- (NSManagedObjectContext *)managedObjectContext
{
    return self.galleryContext;
}

- (NSEntityDescription *)photoEntity
{
    if (self->_photoEntity == nil) {
        assert(self.galleryContext != nil);
        self->_photoEntity = [[NSEntityDescription entityForName:@"Photo" inManagedObjectContext:self.galleryContext] retain];
        assert(self->_photoEntity != nil);
    }
    return self->_photoEntity;
}

@synthesize photoEntity = _photoEntity;

- (NSFetchRequest *)photosFetchRequest
    // Returns a fetch request that gets all of the photos in the database.
{
    NSFetchRequest *    fetchRequest;
    
    fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    assert(fetchRequest != nil);

    [fetchRequest setEntity:self.photoEntity];
    [fetchRequest setFetchBatchSize:20];
    
    return fetchRequest;
}

- (NSString *)galleryCachePathForOurGallery
    // Try to find the gallery cache for our gallery URL string.
{
    NSString *          result;
    NSFileManager *     fileManager;
    NSString *          cachesDirectoryPath;
    NSArray *           potentialGalleries;
    NSString *          galleryName;
    
    assert(self.galleryURLString != nil);
    
    fileManager = [NSFileManager defaultManager];
    assert(fileManager != nil);
    
    cachesDirectoryPath = [[self class] cachesDirectoryPath];
    assert(cachesDirectoryPath != nil);
    
    // First look through the caches directory for a gallery cache whose info file 
    // matches the gallery URL string we're looking for.
    
    potentialGalleries = [fileManager contentsOfDirectoryAtPath:cachesDirectoryPath error:NULL];
    assert(potentialGalleries != nil);
    
    result = nil;
    for (galleryName in potentialGalleries) {
        if ([galleryName hasSuffix:kGalleryExtension]) {
            NSDictionary *  galleryInfo;
            NSString *      galleryInfoURLString;
            
            galleryInfo = [NSDictionary dictionaryWithContentsOfFile:[[cachesDirectoryPath stringByAppendingPathComponent:galleryName] stringByAppendingPathComponent:kInfoFileName]];
            if (galleryInfo != nil) {
                galleryInfoURLString = [galleryInfo objectForKey:kGalleryInfoKeyGalleryURLString];
                if ( [self.galleryURLString isEqual:galleryInfoURLString] ) {
                    result = [cachesDirectoryPath stringByAppendingPathComponent:galleryName];
                    break;
                }
            }
        }
    }
    
    // If we find nothing, create a new gallery cache and record it as belonging to the specified 
    // gallery URL string.
    
    if (result == nil) {
        BOOL        success;

        galleryName = [NSString stringWithFormat:kGalleryNameTemplate, [NSDate timeIntervalSinceReferenceDate], kGalleryExtension];
        assert(galleryName != nil);
        
        result = [cachesDirectoryPath stringByAppendingPathComponent:galleryName];
        success = [fileManager createDirectoryAtPath:result withIntermediateDirectories:NO attributes:NULL error:NULL];
        if (success) {
            NSDictionary *  galleryInfo;
            
            galleryInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.galleryURLString, kGalleryInfoKeyGalleryURLString, nil];
            assert(galleryInfo != nil);
            
            success = [galleryInfo writeToFile:[result stringByAppendingPathComponent:kInfoFileName] atomically:YES];
        }
        if ( ! success ) {
            result = nil;
        }

        [[QLog log] logWithFormat:@"gallery %zu created new '%@'", (size_t) self.sequenceNumber, galleryName];
    } else {
        assert(galleryName != nil);
        [[QLog log] logWithFormat:@"gallery %zu found existing '%@'", (size_t) self.sequenceNumber, galleryName];
    }
    
    return result;
}

- (void)abandonGalleryCacheAtPath:(NSString *)galleryCachePath
    // Abandons the specified gallery cache directory.  We do this simply by removing the gallery 
    // info file.  The directory will be deleted when the application is next launched.
{
    assert(galleryCachePath != nil);

    [[QLog log] logWithFormat:@"gallery %zu abandon '%@'", (size_t) self.sequenceNumber, [galleryCachePath lastPathComponent]];
    
    [[self class] abandonGalleryCacheAtPath:galleryCachePath];
}

- (NSString *)galleryCachePath
{
    assert(self.galleryContext != nil);
    return self.galleryContext.galleryCachePath;
}

- (BOOL)setupGalleryContext
    // Attempt to start up the gallery cache for our gallery URL string, either by finding an existing 
    // cache or by creating one from scratch.  On success, self.galleryCachePath will point to that 
    // gallery cache and self.galleryContext will be the managed object context for the database 
    // within the gallery cache.
{
    BOOL                            success;
    NSError *                       error;
    NSFileManager *                 fileManager;
    NSString *                      galleryCachePath;
    NSString *                      photosDirectoryPath;
    BOOL                            isDir;
    NSURL *                         databaseURL;
    NSManagedObjectModel *          model;
    NSPersistentStoreCoordinator *  psc;

    assert(self.galleryURLString != nil);
    
    [[QLog log] logWithFormat:@"gallery %zu starting", (size_t) self.sequenceNumber];
    
    error = nil;
    
    fileManager = [NSFileManager defaultManager];
    assert(fileManager != nil);
    
    // Find the gallery cache directory for this gallery.
    
    galleryCachePath = [self galleryCachePathForOurGallery];
    success = (galleryCachePath != nil);
    
    // Create the "Photos" directory if it doesn't already exist.
    
    if (success) {
        photosDirectoryPath = [galleryCachePath stringByAppendingPathComponent:kPhotosDirectoryName];
        assert(photosDirectoryPath != nil);
        
        success = [fileManager fileExistsAtPath:photosDirectoryPath isDirectory:&isDir] && isDir;
        if ( ! success ) {
            success = [fileManager createDirectoryAtPath:photosDirectoryPath withIntermediateDirectories:NO attributes:NULL error:NULL];
        }
    }

    // Start up Core Data in the gallery directory.
    
    if (success) {
        NSString *      modelPath;
        
        modelPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Photos" ofType:@"mom"];
        assert(modelPath != nil);
        
        model = [[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]] autorelease];
        success = (model != nil);
    }
    if (success) {
        databaseURL = [NSURL fileURLWithPath:[galleryCachePath stringByAppendingPathComponent:kDatabaseFileName]];
        assert(databaseURL != nil);

        psc = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];
        success = (psc != nil);
    }
    if (success) {
        success = [psc addPersistentStoreWithType:NSSQLiteStoreType 
            configuration:nil 
            URL:databaseURL
            options:nil 
            error:&error
        ] != nil;
        if (success) {
            error = nil;
        }
    }
    
    if (success) {
        PhotoGalleryContext *   context;
        
        // Everything has gone well, so we create a managed object context from our persistent 
        // store.  Note that we use a subclass of NSManagedObjectContext, PhotoGalleryContext, which 
        // carries along some state that the managed objects (specifically the Photo objects) need 
        // access to.

        context = [[[PhotoGalleryContext alloc] initWithGalleryURLString:self.galleryURLString galleryCachePath:galleryCachePath] autorelease];
        assert(context != nil);

        [context setPersistentStoreCoordinator:psc];

        // In older versions of the code various folks observed our photoGalleryContext property 
        // and did clever things when it changed.  So it was important to not set that property 
        // until everything as fully up and running.  That no longer happens, but I've kept the 
        // configure-before-set code because it seems like the right thing to do.
        
        self.galleryContext = context;

        // Subscribe to the context changed notification so that we can auto-save.

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext];

        [[QLog log] logWithFormat:@"gallery %zu started '%@'", (size_t) self.sequenceNumber, [self.galleryCachePath lastPathComponent]];
    } else {
    
        // Bad things happened.  Log the error and return NO.
    
        if (error == nil) {
            [[QLog log] logWithFormat:@"gallery %zu start error", (size_t) self.sequenceNumber];
        } else {
            [[QLog log] logWithFormat:@"gallery %zu start error %@", (size_t) self.sequenceNumber, error];
        }
        
        // Also, if we found or created a gallery cache but failed to start up in it, abandon it in 
        // the hope that our next attempt will work better.
        
        if (galleryCachePath != nil) {
            [self abandonGalleryCacheAtPath:galleryCachePath];
        }
    }
    return success;
}

- (void)start
    // See comment in header.
{
    BOOL                success;

    assert(self.galleryURLString != nil);

    // Try to start up.  If this fails, it abandons the gallery cache, so a retry 
    // on our part is warranted.
    
    success = [self setupGalleryContext];
    if ( ! success ) {
        success = [self setupGalleryContext];
    }
    
    // If all went well, start the syncing processing.  If not, the application is dead 
    // and we crash.
    
    if (success) {
        [self startSync];
    } else {
        abort();
    }
}

@synthesize saveTimer = _saveTimer;

- (void)save
    // See comment in header.
{
    NSError *       error;

    error = nil;
    
    // Disable the auto-save timer.
    
    [self.saveTimer invalidate];
    self.saveTimer = nil;
    
    // Save.
    
    if ( (self.galleryContext != nil) && [self.galleryContext hasChanges] ) {
        BOOL        success;
        
        success = [self.galleryContext save:&error];
        if (success) {
            error = nil;
        }
    }
    
    // Log the results.
    
    if (error == nil) {
        [[QLog log] logWithFormat:@"gallery %zu saved", (size_t) self.sequenceNumber];
    } else {
        [[QLog log] logWithFormat:@"gallery %zu save error %@", (size_t) self.sequenceNumber, error];
    }
}

- (void)contextChanged:(NSNotification *)note
    // Called when the managed object context changes (courtesy of the 
    // NSManagedObjectContextObjectsDidChangeNotification notification).  We start an 
    // auto-save timer to fire in 5 seconds.  This means that rapid-fire changes don't 
    // cause a flood of saves.
{
    #pragma unused(note)
    if (self.saveTimer != nil) {
        [self.saveTimer invalidate];
    }
    self.saveTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(save) userInfo:nil repeats:NO];
}

- (void)stop
    // See comment in header.
    //
    // Shuts down our access to the gallery cache.  We do this in two situations:
    //
    // o When the user switches gallery.
    // o When the application terminates.
{
    [self stopSync];
    
    // Shut down the managed object context.
    
    if (self.galleryContext != nil) {

        // Shut down the auto save mechanism and then force a save.

        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:self.galleryContext];
        
        [self save];
        
        self.photoEntity = nil;
        self.galleryContext = nil;
    }
    [[QLog log] logWithFormat:@"gallery %zu stopped", (size_t) self.sequenceNumber];
}

#pragma mark * Synchronisation

@synthesize getOperation     = _getOperation;
@synthesize parserOperation  = _parserOperation;

@synthesize lastSyncDate     = _lastSyncDate;

+ (NSSet *)keyPathsForValuesAffectingSyncStatus
{
    return [NSSet setWithObjects:@"syncState", @"lastSyncError", @"standardDateFormatter", @"lastSyncDate", @"getOperation.retryStateClient", nil];
}

- (NSString *)syncStatus
    // See comment in header.
{
    NSString *  result;
    
    if (self.lastSyncError == nil) {
        switch (self.syncState) {
            case kPhotoGallerySyncStateStopped: {
                if (self.lastSyncDate == nil) {
                    result = @"Not updated";
                } else {
                    result = [NSString stringWithFormat:@"Updated: %@", [self.standardDateFormatter stringFromDate:self.lastSyncDate]];
                }
            } break;
            default: {
                if ( (self.getOperation != nil) && (self.getOperation.retryStateClient == kRetryingHTTPOperationStateWaitingToRetry) ) {
                    result = @"Waiting for network";
                } else {
                    result = @"Updating…";
                }
            } break;
        }
    } else {
        if ([[self.lastSyncError domain] isEqual:NSCocoaErrorDomain] && [self.lastSyncError code] == NSUserCancelledError) {
            result = @"Update cancelled";
        } else {
            // At this point self.lastSyncError contains the actual error. 
            // However, we ignore that and return a very generic error status. 
            // Users don't understand "Connection reset by peer" anyway (-:
            result = @"Update failed";
        }
    }
    return result;
}

- (NSDateFormatter *)standardDateFormatter
    // See comment in header.
{
    if (self->_standardDateFormatter == nil) {
        self->_standardDateFormatter = [[NSDateFormatter alloc] init];
        assert(self->_standardDateFormatter != nil);
        
        [self->_standardDateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self->_standardDateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        
        // Watch for changes in the locale and time zone so that we can update 
        // our date formatter accordingly.
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStandardDateFormatter:) name:NSCurrentLocaleDidChangeNotification  object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStandardDateFormatter:) name:NSSystemTimeZoneDidChangeNotification object:nil];
    }
    return self->_standardDateFormatter;
}

- (void)updateStandardDateFormatter:(NSNotification *)note
    // Called when either the current locale or the current time zone changes. 
    // We respond by applying the latest values to our date formatter.
{
    #pragma unused(note)
    NSDateFormatter *   df;
    
    df = self.standardDateFormatter;
    [self willChangeValueForKey:@"standardDateFormatter"];
    [df setLocale:[NSLocale currentLocale]];
    [df setTimeZone:[NSTimeZone localTimeZone]];
    [self didChangeValueForKey:@"standardDateFormatter"];
}

@synthesize lastSyncError = _lastSyncError;

+ (BOOL)automaticallyNotifiesObserversOfLastSyncError
{
    return NO;
}

- (void)setLastSyncError:(NSError *)newValue
    // We override this setter purely so that we can log the error.
{
    assert([NSThread isMainThread]);

    if (newValue != nil) {
        [[QLog log] logWithFormat:@"gallery %zu sync error %@", (size_t) self.sequenceNumber, newValue];
    }

    if (newValue != self->_lastSyncError) {
        [self willChangeValueForKey:@"lastSyncError"];
        [self->_lastSyncError release];
        self->_lastSyncError = [newValue copy];
        [self didChangeValueForKey:@"lastSyncError"];
    }
}

- (void)startGetOperation
    // Starts the HTTP operation to GET the photo gallery's XML.
{
    NSMutableURLRequest *   request;

    assert(self.syncState == kPhotoGallerySyncStateStopped);

    [[QLog log] logOption:kLogOptionSyncDetails withFormat:@"gallery %zu sync get start", (size_t) self.sequenceNumber];

    request = [self.galleryContext requestToGetGalleryRelativeString:nil];
    assert(request != nil);
    
    assert(self.getOperation == nil);
    self.getOperation = [[[RetryingHTTPOperation alloc] initWithRequest:request] autorelease];
    assert(self.getOperation != nil);
    
    [self.getOperation setQueuePriority:NSOperationQueuePriorityNormal];
    self.getOperation.acceptableContentTypes = [NSSet setWithObjects:@"application/xml", @"text/xml", nil];
    
    [[NetworkManager sharedManager] addNetworkManagementOperation:self.getOperation finishedTarget:self action:@selector(getOperationDone:)];
    
    self.syncState = kPhotoGallerySyncStateGetting;
}

- (void)getOperationDone:(RetryingHTTPOperation *)operation
    // Called when the HTTP operation to GET the photo gallery's XML completes.  
    // If all is well we start an operation to parse the XML.
{
    NSError *   error;
    
    assert([operation isKindOfClass:[RetryingHTTPOperation class]]);
    assert(operation == self.getOperation);
    assert(self.syncState == kPhotoGallerySyncStateGetting);

    [[QLog log] logOption:kLogOptionSyncDetails withFormat:@"gallery %zu sync listing done", (size_t) self.sequenceNumber];
    
    error = operation.error;
    if (error != nil) {
        self.lastSyncError = error;
        self.syncState = kPhotoGallerySyncStateStopped;
    } else {
        if ([QLog log].isEnabled) {
            [[QLog log] logOption:kLogOptionNetworkData withFormat:@"receive %@", self.getOperation.responseContent];
        }
        [self startParserOperationWithData:self.getOperation.responseContent];
    }
    
    self.getOperation = nil;
}

- (void)startParserOperationWithData:(NSData *)data
    // Starts the operation to parse the gallery's XML.
{
    assert(self.syncState == kPhotoGallerySyncStateGetting);

    [[QLog log] logOption:kLogOptionSyncDetails withFormat:@"gallery %zu sync parse start", (size_t) self.sequenceNumber];

    assert(self.parserOperation == nil);
    self.parserOperation = [[[GalleryParserOperation alloc] initWithData:data] autorelease];
    assert(self.parserOperation != nil);

    [self.parserOperation setQueuePriority:NSOperationQueuePriorityNormal];
    
    [[NetworkManager sharedManager] addCPUOperation:self.parserOperation finishedTarget:self action:@selector(parserOperationDone:)];

    self.syncState = kPhotoGallerySyncStateParsing;
}

- (void)parserOperationDone:(GalleryParserOperation *)operation
    // Called when the operation to parse the gallery's XML completes. 
    // If all went well we commit the results to our database.
{
    assert([NSThread isMainThread]);
    assert([operation isKindOfClass:[GalleryParserOperation class]]);
    assert(operation == self.parserOperation);
    assert(self.syncState == kPhotoGallerySyncStateParsing);

    [[QLog log] logOption:kLogOptionSyncDetails withFormat:@"gallery %zu sync parse done", (size_t) self.sequenceNumber];
    
    if (operation.error != nil) {
        self.lastSyncError = operation.error;
        self.syncState = kPhotoGallerySyncStateStopped;
    } else {
        [self commitParserResults:operation.results];
        
        assert(self.lastSyncError == nil);
        self.lastSyncDate = [NSDate date];
        self.syncState = kPhotoGallerySyncStateStopped;
        [[QLog log] logWithFormat:@"gallery %zu sync success", (size_t) self.sequenceNumber];
    }

    self.parserOperation = nil;
}

#if ! defined(NDEBUG)

- (void)checkDatabase
    // In debug mode we call this routine after committing our changes to the database 
    // to verify that the database looks reasonable.
{
    NSFetchRequest *    photosFetchRequest;
    NSFetchRequest *    thumbnailsFetchRequest;
    NSArray *           allPhotos;
    NSMutableSet *      remainingThumbnails;
    Photo *             photo;
    Thumbnail *         thumbnail;
    
    assert(self.galleryContext != nil);
    
    // Get all of the photos and all of the thumbnails.
    
    photosFetchRequest = [self photosFetchRequest];
    assert(photosFetchRequest != nil);

    allPhotos = [self.galleryContext executeFetchRequest:photosFetchRequest error:NULL];
    assert(allPhotos != nil);

    thumbnailsFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    assert(thumbnailsFetchRequest != nil);

    [thumbnailsFetchRequest setEntity:[NSEntityDescription entityForName:@"Thumbnail" inManagedObjectContext:self.galleryContext]];
    [thumbnailsFetchRequest setFetchBatchSize:20];
    
    remainingThumbnails = [NSMutableSet setWithArray:[self.galleryContext executeFetchRequest:thumbnailsFetchRequest error:NULL]];
    assert(remainingThumbnails != nil);
    
    // Check that ever photo has a thumbnail (and also remove that thumbnail 
    // from the remainingThumbnails set).
    
    for (photo in allPhotos) {        
        assert([photo isKindOfClass:[Photo class]]);
        
        thumbnail = photo.thumbnail;
        if (thumbnail != nil) {
            if ([remainingThumbnails containsObject:thumbnail]) {
                [remainingThumbnails removeObject:thumbnail];
            } else {
                NSLog(@"*** photo %@ has no thumbnail", photo.photoID);
            }
        }
    }
    
    // Check that there are no orphaned thumbnails (thumbnails that aren't attached to 
    // a photo).
    
    for (thumbnail in remainingThumbnails) {
        NSLog(@"*** thumbnail %@ orphaned", thumbnail);
    }
}

#endif

- (void)commitParserResults:(NSArray *)parserResults
    // Commits the results of parsing our the gallery's XML to the Core Data database.
{
    NSError *           error;
    NSDate *            syncDate;
    NSArray *           knownPhotos;    // of Photo

    syncDate = [NSDate date];
    assert(syncDate != nil);

    // Start by getting all of the photos that we currently have in the database.

    knownPhotos = [self.galleryContext executeFetchRequest:[self photosFetchRequest] error:&error];
    assert(knownPhotos != nil);
    if (knownPhotos != nil) {
        NSMutableSet *          photosToRemove;
        NSMutableDictionary *   photoIDToKnownPhotos;
        NSMutableSet *          parserIDs;
        Photo *                 knownPhoto;
        
        // For each photo found in the XML, get the corresponding Photo object 
        // (based on the photoID).  If there is one, update it based on the new 
        // properties from the XML (this may cause the photo to get new thumbnail 
        // and photo images, and trigger significant UI updates).  If there isn't an 
        // existing photo, create one based on the properties from the XML.
        
        // Create photosToRemove, which starts out as a set of all the photos we know 
        // about.  As we refresh each existing photo, we remove it from this set.  Any 
        // photos left over are no longer present in the XML, and we remove them.
        
        photosToRemove = [NSMutableSet setWithArray:knownPhotos];
        assert(photosToRemove != nil);
        
        // Create photoIDToKnownPhotos, which is a map from photoID to photo.  We use this 
        // to quickly determine if a photo with a specific photoID currently exists.
        
        photoIDToKnownPhotos = [NSMutableDictionary dictionary];
        assert(photoIDToKnownPhotos != nil);
        
        for (knownPhoto in knownPhotos) {
            assert([knownPhoto isKindOfClass:[Photo class]]);
            
            [photoIDToKnownPhotos setObject:knownPhoto forKey:knownPhoto.photoID];
        }
        
        // Finally, create parserIDs, which is set of all the photoIDs that have come in 
        // from the XML.  We use this to detect duplicate photoIDs in the incoming XML.  
        // It would be bad to have two photos with the same ID.
        
        parserIDs = [NSMutableSet set];
        assert(parserIDs != nil);
        
        // Iterate through the incoming XML results, processing each one in turn.
        
        for (NSDictionary * parserResult in parserResults) {
            NSString *  photoID;
                        
            photoID  = [parserResult objectForKey:kGalleryParserResultPhotoID];
            assert([photoID isKindOfClass:[NSString class]]);
            
            // Check for duplicates.
            
            if ([parserIDs containsObject:photoID]) {
                [[QLog log] logOption:kLogOptionSyncDetails withFormat:@"gallery %zu sync duplicate photo %@", (size_t) self.sequenceNumber, photoID];
            } else {
                NSDictionary *  properties;
                
                [parserIDs addObject:photoID];
            
                // Build a properties dictionary, used by both the create and update code paths.
                
                properties = [NSDictionary dictionaryWithObjectsAndKeys:
                    photoID,                                                        @"photoID",
                    [parserResult objectForKey:kGalleryParserResultName],           @"displayName", 
                    [parserResult objectForKey:kGalleryParserResultDate],           @"date", 
                    [parserResult objectForKey:kGalleryParserResultPhotoPath],      @"remotePhotoPath", 
                    [parserResult objectForKey:kGalleryParserResultThumbnailPath],  @"remoteThumbnailPath", 
                    nil
                ];
                assert(properties != nil);
            
                // See whether we know about this specific photoID.
                
                knownPhoto = [photoIDToKnownPhotos objectForKey:photoID];
                if (knownPhoto != nil) {
                
                    // Yes.  Give the photo a chance to update itself from the incoming properties.
                
                    [[QLog log] logOption:kLogOptionSyncDetails withFormat:@"gallery %zu sync refresh %@", (size_t) self.sequenceNumber, photoID];
                    [photosToRemove removeObject:knownPhoto];
                    
                    [knownPhoto updateWithProperties:properties];
                } else {
                
                    // No.  Create a new photo with the specified properties.
                    
                    [[QLog log] logOption:kLogOptionSyncDetails withFormat:@"gallery %zu sync create %@", (size_t) self.sequenceNumber, photoID];
                    knownPhoto = [Photo insertNewPhotoWithProperties:properties inManagedObjectContext:self.galleryContext];
                    assert(knownPhoto != nil);
                    assert(knownPhoto.photoID        != nil);
                    assert(knownPhoto.localPhotoPath == nil);
                    assert(knownPhoto.thumbnail      == nil);
                    
                    [photoIDToKnownPhotos setObject:knownPhoto forKey:knownPhoto.photoID];
                }
            }
        }

        // Remove any photos that are no longer present in the XML.

        for (knownPhoto in photosToRemove) {
            [[QLog log] logOption:kLogOptionSyncDetails withFormat:@"gallery %zu sync delete %@", (size_t) self.sequenceNumber, knownPhoto.photoID];
            [self.galleryContext deleteObject:knownPhoto];
        }
    }
    
    #if ! defined(NDEBUG)
        [self checkDatabase];
    #endif
}

+ (NSSet *)keyPathsForValuesAffectingSyncing
{
    return [NSSet setWithObject:@"syncState"];
}

- (BOOL)isSyncing
    // See comment in header.
{
    return (self->_syncState > kPhotoGallerySyncStateStopped);
}

@synthesize syncState = _syncState;

+ (BOOL)automaticallyNotifiesObserversOfSyncState
{
    return NO;
}

- (void)setSyncState:(PhotoGallerySyncState)newValue
{
    if (newValue != self->_syncState) {
        BOOL    isSyncingChanged;
        
        isSyncingChanged = (self->_syncState > kPhotoGallerySyncStateStopped) != (newValue > kPhotoGallerySyncStateStopped);
        [self willChangeValueForKey:@"syncState"];
        if (isSyncingChanged) {
            [self willChangeValueForKey:@"syncing"];
        }
        self->_syncState = newValue;
        if (isSyncingChanged) {
            [self didChangeValueForKey:@"syncing"];
        }
        [self didChangeValueForKey:@"syncState"];
    }
}

- (void)startSync
    // See comment in header.
{
    if ( ! self.isSyncing ) {
        if (self.syncState == kPhotoGallerySyncStateStopped) {
            [[QLog log] logWithFormat:@"gallery %zu sync start", (size_t) self.sequenceNumber];
            assert(self.getOperation == nil);
            self.lastSyncError = nil;
            [self startGetOperation];
        }
    }
}

- (void)stopSync
    // See comment in header.
{
    if (self.isSyncing) {
        if (self.getOperation != nil) {
            [[NetworkManager sharedManager] cancelOperation:self.getOperation];
            self.getOperation = nil;
        }
        if (self.parserOperation) {
            [[NetworkManager sharedManager] cancelOperation:self.parserOperation];
            self.parserOperation = nil;
        }
        self.lastSyncError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
        self.syncState = kPhotoGallerySyncStateStopped;
        [[QLog log] logWithFormat:@"gallery %zu sync stopped", (size_t) self.sequenceNumber];
    }
}

@end
