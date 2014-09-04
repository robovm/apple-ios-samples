/*
    File:       Photo.h

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

#import <CoreData/CoreData.h>

#import <UIKit/UIKit.h>

// When trying to figure out Core Data issues, it's useful to know what photo ID a 
// particular Photo object corresponds to, even if Core Data has forgetten that 
// information (for example, after the object has been deleted, and hence turned 
// into a fault).  So, if you set MVCNETWORKING_KEEP_PHOTO_ID_BACKUP each Photo keeps 
// its own record of the photoID, outside of the scope of Core Data.

#if ! defined(MVCNETWORKING_KEEP_PHOTO_ID_BACKUP)
    #define MVCNETWORKING_KEEP_PHOTO_ID_BACKUP 0
#endif

extern const CGFloat kThumbnailSize;

@class Thumbnail;
@class RetryingHTTPOperation;
@class MakeThumbnailOperation;

@interface Photo : NSManagedObject  
{
#if MVCNETWORKING_KEEP_PHOTO_ID_BACKUP
    NSString *                  _photoIDBackup;
#endif
    UIImage *                   _thumbnailImage;
    BOOL                        _thumbnailImageIsPlaceholder;
    RetryingHTTPOperation *     _thumbnailGetOperation;
    MakeThumbnailOperation *    _thumbnailResizeOperation;
    RetryingHTTPOperation *     _photoGetOperation;
    NSString *                  _photoGetFilePath;
    NSUInteger                  _photoNeededAssertions;
    NSError *                   _photoGetError;
}

+ (Photo *)insertNewPhotoWithProperties:(NSDictionary *)properties inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    // Creates a photo with the specified properties in the specified context. 
    // The properties dictionary is keyed by property names, in a KVC fashion.

- (void)updateWithProperties:(NSDictionary *)properties;
    // Updates the photo with the specified properties.  This will update the various 
    // readonly properties listed below, triggering KVO notifications along the way.

@property (nonatomic, retain, readonly ) NSString *     photoID;                // immutable, unique ID for the photo within this database
@property (nonatomic, retain, readonly ) NSString *     displayName;            // observable, user-visible name of the photo
@property (nonatomic, retain, readonly ) NSDate *       date;                   // observable, date associated with the photo
@property (nonatomic, retain, readonly ) NSString *     localPhotoPath;         // observable, path of the photo file on disk, relative to the PhotoGalleryContext photosDirectoryPath, or nil if not downloaded
@property (nonatomic, retain, readonly ) NSString *     remotePhotoPath;        // observable, URL path of the photo, relative to the PhotoGalleryContext galleryURLString
@property (nonatomic, retain, readonly ) NSString *     remoteThumbnailPath;    // observable, URL path of the thumbnail, relative to the PhotoGalleryContext galleryURLString

@property (nonatomic, retain, readonly ) Thumbnail *    thumbnail;              // observable, pointer to the Thumbnail object, or nil if not downloaded

@property (nonatomic, retain, readonly ) UIImage *      thumbnailImage;         // observable, returns a placeholder if the thumbnail isn't available yet.
@property (nonatomic, retain, readonly ) UIImage *      photoImage;             // observable, returns nil if the photo isn't available yet

// The Photo object does not download the full photo (that is, photoImage) unless someone wants to 
// display it.  Clients should register and unregister their interest in the full photo using these 
// methods.

- (void)assertPhotoNeeded;
- (void)deassertPhotoNeeded;

// Status properties for the photo download operation.  Note that photoGetError is only really 
// interesting if photoImage is nil (indicating that the photo hasn't been downloaded), 
// photoGetting is NO (indicating that the photo is not in the process of being downloaded), 
// -assertPhotoNeeded has been called (indicating that someone actually wants the photo). 
// In that case, photoGetError contains the error from the most recent photo get attempt.

@property (nonatomic, assign, readonly ) BOOL           photoGetting;           // observable
@property (nonatomic, copy,   readonly ) NSError *      photoGetError;          // observable

@end
