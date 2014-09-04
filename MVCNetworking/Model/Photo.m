/*
    File:       Photo.m

    Contains:   Model object for a photo.

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

#import "Photo.h"

#import "Thumbnail.h"

#import "PhotoGalleryContext.h"

#import "MakeThumbnailOperation.h"

#import "NetworkManager.h"

#import "RetryingHTTPOperation.h"
#import "QHTTPOperation.h"

#import "Logging.h"

// After downloading a thumbnail this code automatically reduces the image to a square 
// that's kThumbnailSize x kThumbnailSize.  This is not exactly elegant (what if some 
// other client wanted a different thumbnail size?), but it is very convenient.  It 
// means we can store the data for the reduced thumbnail image in the database, making 
// it very quick to access.  It also means the photo reduce operation is done by this 
// code, right next to the photo get operation.
//
// Ideally you would have a one-to-many relationship between Photo and Thumbnail objects, 
// and the thumbnail would record its own size.  That would allow you to keep thumbnails 
// around for many different clients simultaneously.  I considered that option but decided 
// that it was too complex for this sample.

const CGFloat kThumbnailSize = 60.0f;

@interface Photo ()

// read/write versions of public properties

// IMPORTANT: The default implementation of a managed object property setter does not 
// copy the incoming value.  We could fix this by writing our own setters, but that's a 
// pain.  Instead, we take care to only assign values that are immutable, or to copy the 
// values ourself.  We can do this because the properties are readonly to our external clients.

@property (nonatomic, retain, readwrite) NSString *         photoID;
@property (nonatomic, retain, readwrite) NSString *         displayName;
@property (nonatomic, retain, readwrite) NSDate *           date;
@property (nonatomic, retain, readwrite) NSString *         localPhotoPath;
@property (nonatomic, retain, readwrite) NSString *         remotePhotoPath;
@property (nonatomic, retain, readwrite) NSString *         remoteThumbnailPath;

@property (nonatomic, retain, readwrite) Thumbnail *        thumbnail;

@property (nonatomic, copy,   readwrite) NSError *          photoGetError;

// private properties

@property (nonatomic, retain, readonly ) PhotoGalleryContext *      photoGalleryContext;
@property (nonatomic, retain, readwrite) RetryingHTTPOperation *    thumbnailGetOperation;
@property (nonatomic, retain, readwrite) MakeThumbnailOperation *   thumbnailResizeOperation;
@property (nonatomic, retain, readwrite) RetryingHTTPOperation *    photoGetOperation;
@property (nonatomic, copy,   readwrite) NSString *                 photoGetFilePath;
@property (nonatomic, assign, readwrite) BOOL                       thumbnailImageIsPlaceholder;

// forward declarations

- (void)updateThumbnail;
- (void)updatePhoto;

- (void)thumbnailCommitImage:(UIImage *)image isPlaceholder:(BOOL)isPlaceholder;
- (void)thumbnailCommitImageData:(UIImage *)image;

@end

@implementation Photo 

+ (Photo *)insertNewPhotoWithProperties:(NSDictionary *)properties inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
    // See comment in header.
{
    Photo *     result;
    
    assert(properties != nil);
    assert( [[properties objectForKey:@"photoID"] isKindOfClass:[NSString class]] );
    assert( [[properties objectForKey:@"displayName"] isKindOfClass:[NSString class]] );
    assert( [[properties objectForKey:@"date"] isKindOfClass:[NSDate class]] );
    assert( [[properties objectForKey:@"remotePhotoPath"] isKindOfClass:[NSString class]] );
    assert( [[properties objectForKey:@"remoteThumbnailPath"] isKindOfClass:[NSString class]] );
    assert(managedObjectContext != nil);

    result = (Photo *) [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:managedObjectContext];
    if (result != nil) {
        assert([result isKindOfClass:[Photo class]]);
        
        result.photoID             = [[[properties objectForKey:@"photoID"] copy] autorelease];
        assert(result.photoID != nil);
        #if MVCNETWORKING_KEEP_PHOTO_ID_BACKUP
            result->_photoIDBackup = [result.photoID copy];
        #endif
        result.displayName         = [[[properties objectForKey:@"displayName"] copy] autorelease];
        result.date                = [[[properties objectForKey:@"date"] copy] autorelease];
        result.remotePhotoPath     = [[[properties objectForKey:@"remotePhotoPath"] copy] autorelease];
        result.remoteThumbnailPath = [[[properties objectForKey:@"remoteThumbnailPath"] copy] autorelease];
    }
    return result;
}

#if MVCNETWORKING_KEEP_PHOTO_ID_BACKUP

- (id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context
    // In the debug build we maintain _photoIDBackup to assist with debugging.
{
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    if (self != nil) {
        self->_photoIDBackup = [self.photoID copy];
    }
    return self;
}

#endif

- (void)dealloc
{
    #if MVCNETWORKING_KEEP_PHOTO_ID_BACKUP
        [self->_photoIDBackup release];
    #endif
    [self->_thumbnailImage release];
    assert(self->_thumbnailGetOperation == nil);            // As far as I can tell there are only two ways for these objects to get deallocated, 
    assert(self->_thumbnailResizeOperation == nil);         // namely, the object being deleted and the entire managed object context going away 
    assert(self->_photoGetOperation == nil);                // (which turns the object into a fault).  In both cases -stop runs, which shuts down 
    assert(self->_photoGetFilePath == nil);                 // this stuff.  But the asserts are here, just to be sure.
    [self->_photoGetError release];
    [super dealloc];
}

- (void)updateWithProperties:(NSDictionary *)properties
    // See comment in header.
{
    #pragma unused(properties)
    BOOL    thumbnailNeedsUpdate;
    BOOL    photoNeedsUpdate;
    
    assert( [self.photoID isEqual:[properties objectForKey:@"photoID"]] );
    assert( [[properties objectForKey:@"displayName"] isKindOfClass:[NSString class]] );
    assert( [[properties objectForKey:@"date"] isKindOfClass:[NSDate class]] );
    assert( [[properties objectForKey:@"remotePhotoPath"] isKindOfClass:[NSString class]] );
    assert( [[properties objectForKey:@"remoteThumbnailPath"] isKindOfClass:[NSString class]] );

    if ( ! [self.displayName isEqual:[properties objectForKey:@"displayName"]] ) {
        self.displayName = [[[properties objectForKey:@"displayName"] copy] autorelease];
    }
    
    thumbnailNeedsUpdate = NO;
    photoNeedsUpdate     = NO;
    
    // Look at the date and the various remote paths and decide what needs updating.
    
    if ( ! [self.date isEqual:[properties objectForKey:@"date"]] ) {
        self.date = [[[properties objectForKey:@"date"] copy] autorelease];
        thumbnailNeedsUpdate = YES;
        photoNeedsUpdate     = YES;
    }
    if ( ! [self.remotePhotoPath isEqual:[properties objectForKey:@"remotePhotoPath"]] ) {
        self.remotePhotoPath = [[[properties objectForKey:@"remotePhotoPath"] copy] autorelease];
        photoNeedsUpdate     = YES;
    }
    if ( ! [self.remoteThumbnailPath isEqual:[properties objectForKey:@"remoteThumbnailPath"]] ) {
        self.remoteThumbnailPath = [[[properties objectForKey:@"remoteThumbnailPath"] copy] autorelease];
        thumbnailNeedsUpdate = YES;
    }

    // Do the updates.
    
    if (thumbnailNeedsUpdate) {
        [self updateThumbnail];
    }
    if (photoNeedsUpdate) {
        [self updatePhoto];
    }
}

@dynamic photoID;
@dynamic displayName;
@dynamic date;
@dynamic localPhotoPath;
@dynamic remotePhotoPath;
@dynamic remoteThumbnailPath;

@dynamic thumbnail;

- (PhotoGalleryContext *)photoGalleryContext
{
    PhotoGalleryContext *   result;
    
    result = (PhotoGalleryContext *) [self managedObjectContext];
    assert( [result isKindOfClass:[PhotoGalleryContext class]] );
    
    return result;
}

- (BOOL)stopThumbnail
{
    BOOL    didSomething;
    
    didSomething = NO;
    if (self.thumbnailGetOperation != nil) {
        [self.thumbnailGetOperation removeObserver:self forKeyPath:@"hasHadRetryableFailure"];
        [[NetworkManager sharedManager] cancelOperation:self.thumbnailGetOperation];
        self.thumbnailGetOperation = nil;
        didSomething = YES;
    }
    if (self.thumbnailResizeOperation != nil) {
        [[NetworkManager sharedManager] cancelOperation:self.thumbnailResizeOperation];
        self.thumbnailResizeOperation = nil;
        didSomething = YES;
    }
    return didSomething;
}

- (void)stop
    // Stops all async activity on the object.
{
    BOOL    didSomething;
    
    // If we're currently fetching the thumbnail, cancel that.
    
    didSomething = [self stopThumbnail];
    if (didSomething) {
        [[QLog log] logWithFormat:@"photo %@ thumbnail get stopped", self.photoID];
    }
    
    // If we're currently fetching the photo, cancel that.

    if (self.photoGetOperation != nil) {
        [[NetworkManager sharedManager] cancelOperation:self.photoGetOperation];
        self.photoGetOperation = nil;
        if (self.photoGetFilePath != nil) {
            (void) [[NSFileManager defaultManager] removeItemAtPath:self.photoGetFilePath error:NULL];
            self.photoGetFilePath = nil;
        }
        [[QLog log] logWithFormat:@"photo %@ photo get stopped", self.photoID];
    }
}

- (void)prepareForDeletion
    // We have to override prepareForDeletion in order to get rid of the photo 
    // file.  We take the opportunity to stop any async operations at the 
    // same time.  We'll get a second bite of that cherry in -willTurnIntoFault, 
    // but we might as well do it now.
{
    BOOL    success;
    
    [[QLog log] logWithFormat:@"photo %@ deleted", self.photoID];

    // Stop any asynchronous operations.
    
    [self stop];
    
    // Delete the photo file if it exists on disk.
    
    if (self.localPhotoPath != nil) {
        success = [[NSFileManager defaultManager] removeItemAtPath:[self.photoGalleryContext.photosDirectoryPath stringByAppendingPathComponent:self.localPhotoPath] error:NULL];
        assert(success);
    }
    
    [super prepareForDeletion];
}

- (void)willTurnIntoFault
    // There are three common reasons for turning into a fault:
    // 
    // o Core Data has decided we're uninteresting, and is reclaiming our memory.
    // o We're in the process of being deleted.
    // o The managed object context itself is going away.
    //
    // Regardless of the reason, if we turn into a fault we can any async 
    // operations on the object.  This is especially important in the last 
    // case, where Core Data can't satisfy any fault requests (and, unlike in 
    // the delete case, we didn't get a chance to stop our async operations in 
    // -prepareForDelete).
{
    [self stop];
    [super willTurnIntoFault];
}

#pragma mark * Thumbnails

@synthesize thumbnailGetOperation       = _thumbnailGetOperation;
@synthesize thumbnailResizeOperation    = _thumbnailResizeOperation;
@synthesize thumbnailImageIsPlaceholder = _thumbnailImageIsPlaceholder;

- (void)startThumbnailGet
    // Starts the HTTP operation to GET the photo's thumbnail.
{
    NSURLRequest *      request;
    
    assert(self.remoteThumbnailPath != nil);
    assert(self.thumbnailGetOperation == nil);
    assert(self.thumbnailResizeOperation == nil);
    
    request = [self.photoGalleryContext requestToGetGalleryRelativeString:self.remoteThumbnailPath];
    if (request == nil) {
        [[QLog log] logWithFormat:@"photo %@ thumbnail get bad path '%@'", self.photoID, self.remoteThumbnailPath];
        [self thumbnailCommitImage:nil isPlaceholder:YES];
    } else {
        self.thumbnailGetOperation = [[[RetryingHTTPOperation alloc] initWithRequest:request] autorelease];
        assert(self.thumbnailGetOperation != nil);
        
        [self.thumbnailGetOperation setQueuePriority:NSOperationQueuePriorityLow];
        self.thumbnailGetOperation.acceptableContentTypes = [NSSet setWithObjects:@"image/jpeg", @"image/png", nil];

        [[QLog log] logWithFormat:@"photo %@ thumbnail get start '%@'", self.photoID, self.remoteThumbnailPath];
        
        [self.thumbnailGetOperation addObserver:self forKeyPath:@"hasHadRetryableFailure" options:0 context:&self->_thumbnailImage];
        
        [[NetworkManager sharedManager] addNetworkManagementOperation:self.thumbnailGetOperation finishedTarget:self action:@selector(thumbnailGetDone:)];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->_thumbnailImage) {
        assert(object == self.thumbnailGetOperation);
        assert( [keyPath isEqual:@"hasHadRetryableFailure"] );
        assert([NSThread isMainThread]);
        
        // If we're currently showing a placeholder and the network operation 
        // indicates that it's had one failure, change the placeholder to the deferred 
        // placeholder.  The test for thumbnailImageIsPlaceholder is necessary in the 
        // -updateThumbnail case because we don't want to replace a valid (but old) 
        // thumbnail with a placeholder.
        
        if (self.thumbnailImageIsPlaceholder && self.thumbnailGetOperation.hasHadRetryableFailure) {
            [self thumbnailCommitImage:[UIImage imageNamed:@"Placeholder-Deferred.png"] isPlaceholder:YES];
        }
    } else if (NO) {   // Disabled because the super class does nothing useful with it.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)thumbnailGetDone:(RetryingHTTPOperation *)operation
    // Called when the HTTP operation to GET the photo's thumbnail completes.  
    // If all is well, we start a resize operation to reduce it the appropriate 
    // size.
{
    assert([NSThread isMainThread]);
    assert([operation isKindOfClass:[RetryingHTTPOperation class]]);
    assert(operation == self.thumbnailGetOperation);
    assert([self.thumbnailGetOperation isFinished]);

    assert(self.thumbnailResizeOperation == nil);

    [[QLog log] logWithFormat:@"photo %@ thumbnail get done", self.photoID];
    
    if (operation.error != nil) {
        [[QLog log] logWithFormat:@"photo %@ thumbnail get error %@", self.photoID, operation.error];
        [self thumbnailCommitImage:nil isPlaceholder:YES];
        (void) [self stopThumbnail];
    } else {
        [[QLog log] logOption:kLogOptionNetworkData withFormat:@"receive %@", operation.responseContent];

        // Got the data successfully.  Let's start the resize operation.
        
        self.thumbnailResizeOperation = [[[MakeThumbnailOperation alloc] initWithImageData:operation.responseContent MIMEType:operation.responseMIMEType] autorelease];
        assert(self.thumbnailResizeOperation != nil);

        self.thumbnailResizeOperation.thumbnailSize = kThumbnailSize;
        
        // We want thumbnails resizes to soak up unused CPU time, but the main thread should 
        // always run if it can.  The operation priority is a relative value (courtesy of the 
        // underlying Mach THREAD_PRECEDENCE_POLICY), that is, it sets the priority relative 
        // to other threads in the same process.  A value of 0.5 is the default, so we set a 
        // value significantly lower than that.
        
        if ( [self.thumbnailResizeOperation respondsToSelector:@selector(setThreadPriority:)] ) {
            [self.thumbnailResizeOperation setThreadPriority:0.2];
        }
        [self.thumbnailResizeOperation setQueuePriority:NSOperationQueuePriorityLow];
        
        [[NetworkManager sharedManager] addCPUOperation:self.thumbnailResizeOperation finishedTarget:self action:@selector(thumbnailResizeDone:)];
    }
}

- (void)thumbnailResizeDone:(MakeThumbnailOperation *)operation
    // Called when the operation to resize the thumbnail completes.  
    // If all is well, we commit the thumbnail to our database.
{
    UIImage *   image;
    
    assert([NSThread isMainThread]);
    assert([operation isKindOfClass:[MakeThumbnailOperation class]]);
    assert(operation == self.thumbnailResizeOperation);
    assert([self.thumbnailResizeOperation isFinished]);

    [[QLog log] logWithFormat:@"photo %@ thumbnail resize done", self.photoID];
    
    if (operation.thumbnail == NULL) {
        [[QLog log] logWithFormat:@"photo %@ thumbnail resize failed", self.photoID];
        image = nil;
    } else {
        image = [UIImage imageWithCGImage:operation.thumbnail];
        assert(image != nil);
    }
    
    [self thumbnailCommitImage:image isPlaceholder:NO];
    [self stopThumbnail];
}

- (void)thumbnailCommitImage:(UIImage *)image isPlaceholder:(BOOL)isPlaceholder
    // Commits the thumbnail image to the object itself and to the Core Data database.
{
    // If we were given no image, that's a shortcut for the bad image placeholder.  In 
    // that case we ignore the incoming value of placeholder and force it to YES.
    
    if (image == nil) {
        isPlaceholder = YES;
        image = [UIImage imageNamed:@"Placeholder-Bad.png"];
        assert(image != nil);
    }
    
    // If it was a placeholder, someone else has logged about the failure, so 
    // we only log for real thumbnails.
    
    if ( ! isPlaceholder ) {
        [[QLog log] logWithFormat:@"photo %@ thumbnail commit", self.photoID];
    }
    
    // If we got a non-placeholder image, commit its PNG representation into our thumbnail 
    // database.  To avoid the scroll view stuttering, we only want to do this if the run loop 
    // is running in the default mode.  Thus, we check the mode and either do it directly or 
    // defer the work until the next time the default run loop mode runs.
    //
    // If we were running on iOS 4 or later we could get the PNG representation using 
    // ImageIO, but I want to maintain iOS 3 compatibility for the moment and on that 
    // system we have to use UIImagePNGRepresentation.
    
    if ( ! isPlaceholder ) {
        if ( [[[NSRunLoop currentRunLoop] currentMode] isEqual:NSDefaultRunLoopMode] ) {
            [self thumbnailCommitImageData:image];
        } else {
            [self performSelector:@selector(thumbnailCommitImageData:) withObject:image afterDelay:0.0 inModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
        }
    }
    
    // Commit the change to our thumbnailImage property.
    
    [self willChangeValueForKey:@"thumbnailImage"];
    [self->_thumbnailImage release];
    self->_thumbnailImage = [image retain];
    [self  didChangeValueForKey:@"thumbnailImage"];    
}

- (void)thumbnailCommitImageData:(UIImage *)image
    // Commits the thumbnail data to the Core Data database.
{
    [[QLog log] logWithFormat:@"photo %@ thumbnail commit image data", self.photoID];
    
    // If we have no thumbnail object, create it.
    
    if (self.thumbnail == nil) {
        self.thumbnail = [NSEntityDescription insertNewObjectForEntityForName:@"Thumbnail" inManagedObjectContext:self.managedObjectContext];
        assert(self.thumbnail != nil);
    }
    
    // Stash the data in the thumbnail object's imageData property.
    
    if (self.thumbnail.imageData == nil) {
        self.thumbnail.imageData = UIImagePNGRepresentation(image);
        assert(self.thumbnail.imageData != nil);
    }
}

- (UIImage *)thumbnailImage
{
    if (self->_thumbnailImage == nil) {
        if ( (self.thumbnail != nil) && (self.thumbnail.imageData != nil) ) {
        
            // If we have a thumbnail from the database, return that.
        
            self.thumbnailImageIsPlaceholder = NO;
            self->_thumbnailImage = [[UIImage alloc] initWithData:self.thumbnail.imageData];
            assert(self->_thumbnailImage != nil);
        } else {
            assert(self.thumbnailGetOperation    == nil);   // These should be nil because the only code paths that start 
            assert(self.thumbnailResizeOperation == nil);   // a get also ensure there's a thumbnail in place (either a 
                                                            // placeholder or the old thumbnail).
        
            // Otherwise, return the placeholder and kick off a get (unless we're 
            // already getting).
        
            self.thumbnailImageIsPlaceholder = YES;
            self->_thumbnailImage = [[UIImage imageNamed:@"Placeholder.png"] retain];
            assert(self->_thumbnailImage != nil);
            
            [self startThumbnailGet];
        }
    }
    return self->_thumbnailImage;
}

- (void)updateThumbnail
    // Updates the thumbnail is response to a change in the photo's XML entity.
{
    [[QLog log] logWithFormat:@"photo %@ update thumbnail", self.photoID];

    // We only do an update if we've previously handed out a thumbnail image. 
    // If not, the thumbnail will be fetched normally when the client first 
    // requests an image.
    
    if (self->_thumbnailImage != nil) {
    
        // If we're already getting a thumbnail, stop that get (it may be getting from 
        // the old path).
        
        (void) [self stopThumbnail];
        
        // Nix our thumbnail data.  This ensures that, if we quit before the get is complete, 
        // then, on relaunch, we will notice that we need to get the thumbnail.
        
        if (self.thumbnail != nil) {
            self.thumbnail.imageData = nil;
        }
        
        // Kick off the network get.  Note that we don't nix _thumbnailImage here.  The client 
        // will continue to see the old thumbnail (which might be a placeholder) until the 
        // get completes.
        
        [self startThumbnailGet];
    }
}

#pragma mark * Photos

@synthesize photoGetOperation = _photoGetOperation;
@synthesize photoGetFilePath  = _photoGetFilePath;
@synthesize photoGetError     = _photoGetError;

- (void)startPhotoGet
    // Starts the HTTP operation to GET the photo itself.
{
    NSURLRequest *      request;

    assert(self.remotePhotoPath != nil);
    // assert(self.localPhotoPath  == nil);     -- May be non-nil when we're updating the photo.
    assert( ! self.photoGetting );

    assert(self.photoGetOperation == nil);
    assert(self.photoGetFilePath == nil);
    
    self.photoGetError = nil;
    
    request = [self.photoGalleryContext requestToGetGalleryRelativeString:self.remotePhotoPath];
    if (request == nil) {
        [[QLog log] logWithFormat:@"photo %@ photo get bad path '%@'", self.photoID, self.remotePhotoPath];
        self.photoGetError = [NSError errorWithDomain:kQHTTPOperationErrorDomain code:400 userInfo:nil];
    } else {

        // We start by downloading the photo to a temporary file.  Create an output stream 
        // for that file.
        
        self.photoGetFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"PhotoTemp-%.9f", [NSDate timeIntervalSinceReferenceDate]]];
        assert(self.photoGetFilePath != nil);
        
        // Create, configure, and start the download operation.
        
        self.photoGetOperation = [[[RetryingHTTPOperation alloc] initWithRequest:request] autorelease];
        assert(self.photoGetOperation != nil);
        
        [self.photoGetOperation setQueuePriority:NSOperationQueuePriorityHigh];
        self.photoGetOperation.responseFilePath = self.photoGetFilePath;
        self.photoGetOperation.acceptableContentTypes = [NSSet setWithObjects:@"image/jpeg", @"image/png", nil];

        [[QLog log] logWithFormat:@"photo %@ photo get start '%@'", self.photoID, self.remotePhotoPath];
        
        [[NetworkManager sharedManager] addNetworkManagementOperation:self.photoGetOperation finishedTarget:self action:@selector(photoGetDone:)];
    }
}

- (void)photoGetDone:(RetryingHTTPOperation *)operation
    // Called when the HTTP operation to GET the photo completes.  
    // If all is well, we commit the photo to the database.
{
    assert([NSThread isMainThread]);
    assert([operation isKindOfClass:[RetryingHTTPOperation class]]);
    assert(operation == self.photoGetOperation);

    [[QLog log] logWithFormat:@"photo %@ photo get done", self.photoID];
    
    if (operation.error != nil) {
        [[QLog log] logWithFormat:@"photo %@ photo get error %@", self.photoID, operation.error];
        self.photoGetError = operation.error;
    } else {
        BOOL        success;
        NSString *  type;
        NSString *  extension;
        NSString *  fileName;
        NSUInteger  fileCounter;
        NSError *   error;
        
        // Can't log the incoming data becauses it went directly to disk.
        // 
        // [[QLog log] logOption:kLogOptionNetworkData withFormat:@"receive %@", operation.responseContent];
        
        // Just to keep things sane, we set the file name extension based on the MIME type.
        
        type = operation.responseMIMEType;
        assert(type != nil);
        if ([type isEqual:@"image/png"]) {
            extension = @"png";
        } else {
            assert([type isEqual:@"image/jpeg"]);
            extension = @"jpg";
        }
        
        // Move the file to the gallery's photo directory, and if that's successful, set localPhotoPath 
        // to point to it.  We automatically rename the file to avoid conflicts.  Conflicts do happen 
        // in day-to-day operations (specifically, in the case where we update a photo while actually 
        // displaying that photo).
        
        fileCounter = 0;
        do {
            fileName = [NSString stringWithFormat:@"Photo-%@-%zu.%@", self.photoID, (size_t) fileCounter, extension];
            assert(fileName != nil);
            
            success = [[NSFileManager defaultManager] moveItemAtPath:self.photoGetFilePath toPath:[self.photoGalleryContext.photosDirectoryPath stringByAppendingPathComponent:fileName] error:&error];
            if ( success ) {
                self.photoGetFilePath = nil;
                break;
            }
            fileCounter += 1;
            if (fileCounter > 100) {
                break;
            }
        } while (YES);

        // On success, update localPhotoPath to point to the newly downloaded photo 
        // and then delete the previous photo (if any).
        
        if (success) {
            NSString *  oldLocalPhotoPath;
            
            oldLocalPhotoPath = [[self.localPhotoPath copy] autorelease];
            
            [[QLog log] logWithFormat:@"photo %@ photo get commit '%@'", self.photoID, fileName];
            self.localPhotoPath = fileName;
            assert(self.photoGetError == nil);
            
            if (oldLocalPhotoPath != nil) {
                [[QLog log] logWithFormat:@"photo %@ photo cleanup '%@'", self.photoID, oldLocalPhotoPath];
                (void) [[NSFileManager defaultManager] removeItemAtPath:[self.photoGalleryContext.photosDirectoryPath stringByAppendingPathComponent:oldLocalPhotoPath] error:NULL];
            }
        } else {
            assert(error != nil);
            [[QLog log] logWithFormat:@"photo %@ photo get commit failed %@", self.photoID, error];
            self.photoGetError = error;
        }
    }
    
    // Clean up.
    
    self.photoGetOperation = nil;
    if (self.photoGetFilePath != nil) {
        (void) [[NSFileManager defaultManager] removeItemAtPath:self.photoGetFilePath error:NULL];
        self.photoGetFilePath = nil;
    }
}

+ (NSSet *)keyPathsForValuesAffectingPhotoImage
{
    return [NSSet setWithObject:@"localPhotoPath"];
}

- (UIImage *)photoImage
    // See comment in header.
{
    UIImage *   result;
    
    // Note that we don't retain the photo here.  Photos are large, and holding on to them here 
    // is probably a mistake.  It's likely that the caller is going to retain the photo anyway 
    // (by putting it into an image view, say).
    
    if (self.localPhotoPath == nil) {
        result = nil;
    } else {
        result = [UIImage imageWithContentsOfFile:[self.photoGalleryContext.photosDirectoryPath stringByAppendingPathComponent:self.localPhotoPath]];
        if (result == nil) {
            [[QLog log] logWithFormat:@"photo %@ photo data bad", self.photoID];
        }
    }
    return result;
}

+ (NSSet *)keyPathsForValuesAffectingPhotoGetting
{
    return [NSSet setWithObject:@"photoGetOperation"];
}

- (BOOL)photoGetting
    // See comment in header.
{
    return (self.photoGetOperation != nil);
}

- (void)assertPhotoNeeded
    // See comment in header.
{
    self->_photoNeededAssertions += 1;
    if ( (self.localPhotoPath == nil) && ! self.photoGetting ) {
        [self startPhotoGet];
    }
}

- (void)deassertPhotoNeeded
    // See comment in header.
{
    assert(self->_photoNeededAssertions != 0);
    self->_photoNeededAssertions -= 1;
}

- (void)updatePhoto
    // Updates the photo is response to a change in the photo's XML entity.
{
    [[QLog log] logWithFormat:@"photo %@ update photo", self.photoID];

    // We only fetch the photo is someone is actively looking at it.  Otherwise 
    // we just nix our record of the photo and fault it in as per usual the next 
    // time that someone asserts that they need it.

    if (self->_photoNeededAssertions == 0) {
    
        // No one is actively looking at the photo.  If we have the photo downloaded, 
        // just forget about it.
    
        if (self.localPhotoPath != nil) {
            [[QLog log] logWithFormat:@"photo %@ photo delete old photo '%@'", self.photoID, self.localPhotoPath];
            [[NSFileManager defaultManager] removeItemAtPath:[self.photoGalleryContext.photosDirectoryPath stringByAppendingPathComponent:self.localPhotoPath] error:NULL];
            self.localPhotoPath = nil;
        }
    } else {

        // If we're already getting the photo, stop that get (it may be getting from 
        // the old path).
        
        if (self.photoGetOperation != nil) {
            [[NetworkManager sharedManager] cancelOperation:self.photoGetOperation];
            self.photoGetOperation = nil;
        }
        
        // Someone is actively looking at the photo.  We start a new download, which 
        // will download the new photo to a new file.  When that completes, it will 
        // change localPhotoPath to point to the new file and then delete the old 
        // file.
        // 
        // Note that we don't trigger a KVO notification on photoImage at this point. 
        // Instead we leave the user looking at the old photo; it's better than nothing (-:
        
        [self startPhotoGet];
    }
}

@end
