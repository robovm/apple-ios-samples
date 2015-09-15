/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class used to keep track of known documents in the cloud.
 */

#import "AAPLCloudDocumentsController.h"

@interface AAPLCloudDocumentsController ()

- (void)removeQueryObservers;
- (void)addQueryObservers;

@property (nonatomic, strong) NSMetadataQuery *ubiquitousQuery;

@end


#pragma mark -

@implementation AAPLCloudDocumentsController

static AAPLCloudDocumentsController *cloudDocumentsController;

// -------------------------------------------------------------------------------
//  singleton class
// -------------------------------------------------------------------------------
+ (AAPLCloudDocumentsController *)sharedInstance
{
    if (cloudDocumentsController == nil)
    {
        // note: an empty file type means find all types documents
        cloudDocumentsController = [[AAPLCloudDocumentsController alloc] initWithType:@""];
    }
    return cloudDocumentsController;
}

// -------------------------------------------------------------------------------
//  setupQuery
// -------------------------------------------------------------------------------
- (void)setupQuery
{
    _ubiquitousQuery = [[NSMetadataQuery alloc] init];
    self.ubiquitousQuery.notificationBatchingInterval = 15;
    self.ubiquitousQuery.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
    
    NSString *filePattern = nil;
    if ([self.fileType isEqualToString:@""])
    {
        filePattern = [NSString stringWithFormat:@"*.*"];
    }
    else
    {
        filePattern = [NSString stringWithFormat:@"*.%@", self.fileType];
    }
    
    self.ubiquitousQuery.predicate = [NSPredicate predicateWithFormat:@"%K LIKE %@", NSMetadataItemFSNameKey, filePattern];
    // or 
    // _ubiquitousQuery.predicate = [NSPredicate predicateWithFormat:@"%K ENDSWITH %@", NSMetadataItemFSNameKey, self.fileType];
    
    NSSortDescriptor *sortKeys = [[NSSortDescriptor alloc] initWithKey:NSMetadataItemFSNameKey ascending:YES];
    [self.ubiquitousQuery setSortDescriptors:@[sortKeys]];
}

// -------------------------------------------------------------------------------
//  initWithType:fileType
// -------------------------------------------------------------------------------
- (instancetype)initWithType:(NSString *)fileType
{
    self = [super init];
    if (self != nil)
    {
        _fileType = fileType;
    
        [self setupQuery];
    }
    
    return self;
}

// -------------------------------------------------------------------------------
//  initWithType:fileType
//
//  Our client is explicty setting the file type, so we need to re-setup the query.
// -------------------------------------------------------------------------------
- (void)setFileType:(NSString *)fileType
{
    _fileType = fileType;
    [self setupQuery];
}


#pragma mark - Exported APIs

// -------------------------------------------------------------------------------
//  numberOfDocuments
// -------------------------------------------------------------------------------
- (NSUInteger)numberOfDocuments
{
    return self.ubiquitousQuery.resultCount;
}

// -------------------------------------------------------------------------------
//  startScanning
// -------------------------------------------------------------------------------
- (BOOL)startScanning
{
    BOOL started = NO;
    
    // first make sure we are logged into iCloud
    id ubiquityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
    if (ubiquityToken != nil)
    {
        [self addQueryObservers];

        started = [_ubiquitousQuery startQuery];
        if (!started)
        {
            self.ubiquitousQuery = nil;
        }
    }
    
    return started;
}

// -------------------------------------------------------------------------------
//  stopScanning
// -------------------------------------------------------------------------------
- (void)stopScanning
{
    [self.ubiquitousQuery stopQuery];
    [self removeQueryObservers];
    
    self.ubiquitousQuery = nil;
}

// -------------------------------------------------------------------------------
//  restartScan
// -------------------------------------------------------------------------------
- (void)restartScan
{
    [self.ubiquitousQuery stopQuery];
    
    self.ubiquitousQuery = nil;
    
    [self setupQuery];
    [self startScanning];
}

// -------------------------------------------------------------------------------
//  urlForDocumentAtIndex:index
// -------------------------------------------------------------------------------
- (NSURL *)urlForDocumentAtIndex:(NSInteger)index
{
    NSMetadataItem *item = self.ubiquitousQuery.results[index];
    NSURL *itemURL = [item valueForAttribute:NSMetadataItemURLKey];
    return itemURL;
}

// -------------------------------------------------------------------------------
//  titleForDocumentAtIndex:index
// -------------------------------------------------------------------------------
- (NSString *)titleForDocumentAtIndex:(NSInteger)index
{
    NSMetadataItem *item = self.ubiquitousQuery.results[index];
    NSURL *itemURL = [item valueForAttribute:NSMetadataItemURLKey];
    NSURL *urlWithoutExtension = [itemURL URLByDeletingPathExtension];
    NSString *result = [urlWithoutExtension lastPathComponent];
    return result;
}

// -------------------------------------------------------------------------------
//  iconForDocumentAtIndex:index
// -------------------------------------------------------------------------------
#if TARGET_OS_IPHONE
- (UIImage *)iconForDocumentAtIndex:(NSInteger)index
{
    NSMetadataItem *item = self.ubiquitousQuery.results[index];
    NSURL *itemURL = [item valueForAttribute:NSMetadataItemURLKey];

    UIDocumentInteractionController *controller = [UIDocumentInteractionController interactionControllerWithURL:itemURL];
    return controller.icons[0];
}
#else
- (NSImage *)iconForDocumentAtIndex:(NSInteger)index
{
    NSImage *icon = nil;
    
    NSMetadataItem *item = self.ubiquitousQuery.results[index];
    NSURL *itemURL = [item valueForAttribute:NSMetadataItemURLKey];
    [itemURL getResourceValue:&icon forKey:NSURLEffectiveIconKey error:nil];
    
    return icon;
}
#endif

// -------------------------------------------------------------------------------
//  modDateForDocumentAtIndex:index
// -------------------------------------------------------------------------------
- (NSDate *)modDateForDocumentAtIndex:(NSInteger)index
{
    NSDate *modDate = nil;
    
    NSMetadataItem *item = self.ubiquitousQuery.results[index];
    NSURL *itemURL = [item valueForAttribute:NSMetadataItemURLKey];
    [itemURL getResourceValue:&modDate forKey:NSURLContentModificationDateKey error:nil];
    
    return modDate;
}

// -------------------------------------------------------------------------------
//  documentIsUploadedAtIndex:index
// -------------------------------------------------------------------------------
- (BOOL)documentIsUploadedAtIndex:(NSInteger)index
{
    // get uploaded state: true if there is data present in the cloud for this item
    NSMetadataItem *item = self.ubiquitousQuery.results[index];
    NSNumber *isUploaded = [item valueForAttribute:NSMetadataUbiquitousItemIsUploadedKey];
    return [isUploaded boolValue];
}

// -------------------------------------------------------------------------------
//  documentIsDownloadedAtIndex:index
// -------------------------------------------------------------------------------
- (BOOL)documentIsDownloadedAtIndex:(NSInteger)index
{
    // get uploaded state: true if download status = NSMetadataUbiquitousItemDownloadingStatusCurrent
    NSMetadataItem *item = self.ubiquitousQuery.results[index];
    NSString *downloadStatus = [item valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey];
    return [downloadStatus isEqualToString:NSMetadataUbiquitousItemDownloadingStatusCurrent];
}


#pragma mark - Querying

// -------------------------------------------------------------------------------
//  addQueryObservers
// -------------------------------------------------------------------------------
- (void)addQueryObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didStart:)
                                                 name:NSMetadataQueryDidStartGatheringNotification
                                               object:_ubiquitousQuery];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gathering:)
                                                 name:NSMetadataQueryGatheringProgressNotification
                                               object:_ubiquitousQuery];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishGathering:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:_ubiquitousQuery];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdate:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:_ubiquitousQuery];
}

// -------------------------------------------------------------------------------
//  removeQueryObservers
// -------------------------------------------------------------------------------
- (void)removeQueryObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidStartGatheringNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryGatheringProgressNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidFinishGatheringNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidUpdateNotification
                                                  object:nil];
}

// -------------------------------------------------------------------------------
//  dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
    [self removeQueryObservers];
}

// -------------------------------------------------------------------------------
//  didStart:note
//
//  NSMetadataQuery has started.
// -------------------------------------------------------------------------------
- (void)didStart:(NSNotification *)note
{
    //NSLog(@"didStart...");
    
    // call our delegate that we started scanning out ubiquitous container
    if ([self.delegate respondsToSelector:@selector(didStartRetrievingCloudDocuments)])
    {
        [self.delegate didStartRetrievingCloudDocuments];
    }
}

// -------------------------------------------------------------------------------
//  gathering:note
//
//  NSMetadataQuery is gathering the results.
// -------------------------------------------------------------------------------
- (void)gathering:(NSNotification *)note
{
    //NSLog(@"gathering...");
    
    //.. do what ever you need to do while gathering results
}

// -------------------------------------------------------------------------------
//  handleQueryUpdates:ubiquitousQuery
//
//  Used for examining what new results came from our NSMetadataQuery.
//  This method is shared between "finishGathering" and "didUpdate" methods.
// -------------------------------------------------------------------------------
- (void)handleQueryUpdates:(NSMetadataQuery *)ubiquitousQuery
{
    // we should invoke this method before iterating over query results that could
    // change due to live updates
    [self.ubiquitousQuery disableUpdates];
    
    // notify our delegate we received an update
    if ([self.delegate respondsToSelector:@selector(didRetrieveCloudDocuments)])
    {
        [self.delegate didRetrieveCloudDocuments];
    }
    
    // enable updates again
    [self.ubiquitousQuery enableUpdates];
}

// -------------------------------------------------------------------------------
//  finishGathering:note
// -------------------------------------------------------------------------------
- (void)finishGathering:(NSNotification *)note
{
    //NSLog(@"finishGathering...");
    
    [self handleQueryUpdates:self.ubiquitousQuery];
    
    // for debugging
    /*for (NSMetadataItem *item in self.ubiquitousQuery.results)
    {
        NSURL *itemURL = [item valueForAttribute:NSMetadataItemURLKey];
        NSURL *urlWithoutExtension = [itemURL URLByDeletingPathExtension];
        NSString *result = [urlWithoutExtension lastPathComponent];
        NSLog(@"%@", result);
    }*/
}

// -------------------------------------------------------------------------------
//  didUpdate:note
// -------------------------------------------------------------------------------
- (void)didUpdate:(NSNotification *)note
{
    //NSLog(@"didUpdate...");
    
    [self handleQueryUpdates:self.ubiquitousQuery];
}

@end
