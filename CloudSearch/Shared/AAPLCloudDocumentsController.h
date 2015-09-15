/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class used to keep track of known documents in the cloud.
 */

#import <Foundation/Foundation.h>

@protocol AAPLCloudDocumentsControllerDelegate;

@interface AAPLCloudDocumentsController : NSObject

@property (nonatomic, weak, readwrite) id <AAPLCloudDocumentsControllerDelegate> delegate;
@property (nonatomic, strong) NSString *fileType;

+ (AAPLCloudDocumentsController *)sharedInstance;

- (instancetype)initWithType:(NSString *)fileType NS_DESIGNATED_INITIALIZER;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL startScanning;
- (void)stopScanning;
- (void)restartScan;

@property (NS_NONATOMIC_IOSONLY, readonly) NSUInteger numberOfDocuments;

// obtaining information about a cloud document
- (NSURL *)urlForDocumentAtIndex:(NSInteger)index;
- (NSString *)titleForDocumentAtIndex:(NSInteger)index;

#if TARGET_OS_IPHONE
- (UIImage *)iconForDocumentAtIndex:(NSInteger)index;
#else
- (NSImage *)iconForDocumentAtIndex:(NSInteger)index;
#endif
- (NSDate *)modDateForDocumentAtIndex:(NSInteger)index;
- (BOOL)documentIsUploadedAtIndex:(NSInteger)index;
- (BOOL)documentIsDownloadedAtIndex:(NSInteger)index;

@end

@protocol AAPLCloudDocumentsControllerDelegate <NSObject>
@required
- (void)didRetrieveCloudDocuments;          // notify delegate when cloud documents are found
- (void)didStartRetrievingCloudDocuments;   // notify delegate when starting search of cloud documents  
@end