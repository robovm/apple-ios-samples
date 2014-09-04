/*
    File:       PhotoGallery.h

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

#import <CoreData/CoreData.h>

/*
    This class manages a collection of photos from a gallery on the network at a 
    specified URL.  You construct it with the URL of the gallery.  It then attempts 
    to find a corresponding gallery cache in the caches directory.  If not is found, 
    it creates a new blank one.  Within that gallery cache there is a Core Data 
    database that holds the model objects and a "Photos" directory that stores actual 
    photos.  Thus this class owns the Core Data managed object context that's used by 
    other parts of the application, and it exports certain aspects of that context 
    to help out things like the PhotoGalleryViewController.
    
    This class takes care of downloading the XML specification of the photo 
    gallery and syncing it with our local view of the gallery held in our Core Data 
    database, adding any photos we haven't seen before and removing any photos that 
    are no longer in the gallery.
*/

enum PhotoGallerySyncState {
    kPhotoGallerySyncStateStopped, 
    kPhotoGallerySyncStateGetting, 
    kPhotoGallerySyncStateParsing, 
    kPhotoGallerySyncStateCommitting
};
typedef enum PhotoGallerySyncState PhotoGallerySyncState;

@class PhotoGalleryContext;
@class RetryingHTTPOperation;
@class GalleryParserOperation;

@interface PhotoGallery : NSObject {
    NSString *                      _galleryURLString;
    NSUInteger                      _sequenceNumber;
    
    PhotoGalleryContext *           _galleryContext;
    NSEntityDescription *           _photoEntity;
    NSTimer *                       _saveTimer;

    NSDate *                        _lastSyncDate;
    NSError *                       _lastSyncError;
    NSDateFormatter *               _standardDateFormatter;
    PhotoGallerySyncState           _syncState;
    RetryingHTTPOperation *         _getOperation;
    GalleryParserOperation *        _parserOperation;
}

#pragma mark * Start up and shut down

+ (void)applicationStartup;
    // Called by the application delegate at startup time.  This takes care of 
    // various bits of bookkeeping, including resetting the cache of photos 
    // if that debugging option has been set.

- (id)initWithGalleryURLString:(NSString *)galleryURLString;

@property (nonatomic, copy,   readonly ) NSString *                 galleryURLString;

- (void)start;
    // Starts up the gallery (finds or creates a cache database and kicks off the initial 
    // sync).

- (void)save;
- (void)stop;
    // Called by the application delegate at -applicationDidEnterBackground: and 
    // -applicationWillTerminate: time, respectively.  Note that it's safe, albeit a little 
    // weird, to call -save and -stop even if you haven't called -start.
    //
    // -stop is also called by the application delegate when it switches to a new gallery.

#pragma mark * Core Data accessors

// These properties are exported for the benefit of the PhotoGalleryViewController class, which 
// uses them to set up its fetched results controller.

@property (nonatomic, retain, readonly ) NSManagedObjectContext *   managedObjectContext;       // observable
@property (nonatomic, retain, readonly ) NSEntityDescription *      photoEntity;
    // Returns the entity description for the "Photo" entity in our database.

#pragma mark * Syncing

// These properties allow user interface controllers to learn about and control the 
// state of the syncing process.

@property (nonatomic, assign, readonly, getter=isSyncing) BOOL      syncing;                    // observable, YES if syncState > kPhotoGallerySyncStateStopped
@property (nonatomic, assign, readonly ) PhotoGallerySyncState      syncState;
@property (nonatomic, copy,   readonly ) NSString *                 syncStatus;                 // observable, user-visible sync status
@property (nonatomic, copy,   readonly ) NSDate *                   lastSyncDate;               // observable, date of last /successful/ sync
@property (nonatomic, copy,   readonly ) NSError *                  lastSyncError;              // observable, error for last sync

@property (nonatomic, copy,   readonly ) NSDateFormatter *          standardDateFormatter;      // observable, date formatter for general purpose use

- (void)startSync;
    // Force a sync to start right now.  Does nothing if a sync is already in progress.
    
- (void)stopSync;
    // Force a sync to stop right now.  Does nothing if a no sync is in progress.

@end
