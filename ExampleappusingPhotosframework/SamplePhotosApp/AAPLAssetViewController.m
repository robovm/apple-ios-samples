/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view controller displaying an asset full screen.
  
 */

#import "AAPLAssetViewController.h"


@implementation CIImage (Convenience)
- (NSData *)aapl_jpegRepresentationWithCompressionQuality:(CGFloat)compressionQuality {
	static CIContext *ciContext = nil;
	if (!ciContext) {
		EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		ciContext = [CIContext contextWithEAGLContext:eaglContext];
	}
	CGImageRef outputImageRef = [ciContext createCGImage:self fromRect:[self extent]];
	UIImage *uiImage = [[UIImage alloc] initWithCGImage:outputImageRef scale:1.0 orientation:UIImageOrientationUp];
	if (outputImageRef) {
		CGImageRelease(outputImageRef);
	}
	NSData *jpegRepresentation = UIImageJPEGRepresentation(uiImage, compressionQuality);
	return jpegRepresentation;
}
@end


@interface AAPLAssetViewController () <PHPhotoLibraryChangeObserver>
@property (weak) IBOutlet UIImageView *imageView;
@property (strong) IBOutlet UIBarButtonItem *playButton;
@property (strong) IBOutlet UIBarButtonItem *space;
@property (strong) IBOutlet UIBarButtonItem *trashButton;
@property (strong) IBOutlet UIBarButtonItem *editButton;
@property (strong) IBOutlet UIProgressView *progressView;
@property (strong) AVPlayerLayer *playerLayer;
@property (assign) CGSize lastImageViewSize;
@end


@implementation AAPLAssetViewController

static NSString * const AdjustmentFormatIdentifier = @"com.example.apple-samplecode.SamplePhotosApp";

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.asset.mediaType == PHAssetMediaTypeVideo) {
        self.toolbarItems = @[self.playButton, self.space, self.trashButton];
    } else {
        self.toolbarItems = @[self.space, self.trashButton];
    }
    
    BOOL isEditable = ([self.asset canPerformEditOperation:PHAssetEditOperationProperties] || [self.asset canPerformEditOperation:PHAssetEditOperationContent]);
    self.editButton.enabled = isEditable;
    
    BOOL isTrashable = NO;
    if (self.assetCollection) {
        isTrashable = [self.assetCollection canPerformEditOperation:PHCollectionEditOperationRemoveContent];
    } else {
        isTrashable = [self.asset canPerformEditOperation:PHAssetEditOperationDelete];
    }
    self.trashButton.enabled = isTrashable;
    
    [self.view layoutIfNeeded];
    [self updateImage];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (!CGSizeEqualToSize(self.imageView.bounds.size, self.lastImageViewSize)) {
        [self updateImage];
    }
}

- (void)updateImage
{
    self.lastImageViewSize = self.imageView.bounds.size;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize targetSize = CGSizeMake(CGRectGetWidth(self.imageView.bounds) * scale, CGRectGetHeight(self.imageView.bounds) * scale);
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    
    // Download from cloud if necessary
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
            self.progressView.hidden = (progress <= 0.0 || progress >= 1.0);
        });
    };
    
    [[PHImageManager defaultManager] requestImageForAsset:self.asset targetSize:targetSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        if (result) {
            self.imageView.image = result;
        }
    }];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // check if there are changes to the album we're interested on (to its metadata, not to its collection of assets)
        PHObjectChangeDetails *changeDetails = [changeInstance changeDetailsForObject:self.asset];
        if (changeDetails) {
            // it changed, we need to fetch a new one
            self.asset = [changeDetails objectAfterChanges];
            
            if ([changeDetails assetContentChanged]) {
                [self updateImage];
                
                if (self.playerLayer) {
                    [self.playerLayer removeFromSuperlayer];
                    self.playerLayer = nil;
                }
            }
        }
        
    });
}

#pragma mark - Actions

- (void)applyFilterWithName:(NSString *)filterName
{
    PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
    [options setCanHandleAdjustmentData:^BOOL(PHAdjustmentData *adjustmentData) {
        return [adjustmentData.formatIdentifier isEqualToString:AdjustmentFormatIdentifier] && [adjustmentData.formatVersion isEqualToString:@"1.0"];
    }];
    [self.asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
        // Get full image
        NSURL *url = [contentEditingInput fullSizeImageURL];
        int orientation = [contentEditingInput fullSizeImageOrientation];
        CIImage *inputImage = [CIImage imageWithContentsOfURL:url options:nil];
        inputImage = [inputImage imageByApplyingOrientation:orientation];

        // Add filter
        CIFilter *filter = [CIFilter filterWithName:filterName];
        [filter setDefaults];
        [filter setValue:inputImage forKey:kCIInputImageKey];
        CIImage *outputImage = [filter outputImage];

        // Create editing output
        NSData *jpegData = [outputImage aapl_jpegRepresentationWithCompressionQuality:0.9f];
        PHAdjustmentData *adjustmentData = [[PHAdjustmentData alloc] initWithFormatIdentifier:AdjustmentFormatIdentifier formatVersion:@"1.0" data:[filterName dataUsingEncoding:NSUTF8StringEncoding]];
        
        PHContentEditingOutput *contentEditingOutput = [[PHContentEditingOutput alloc] initWithContentEditingInput:contentEditingInput];
        [jpegData writeToURL:[contentEditingOutput renderedContentURL] atomically:YES];
        [contentEditingOutput setAdjustmentData:adjustmentData];
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:self.asset];
            request.contentEditingOutput = contentEditingOutput;
        } completionHandler:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"Error: %@", error);
            }
        }];
    }];
}

- (IBAction)handleEditButtonItem:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:NULL]];

    if ([self.asset canPerformEditOperation:PHAssetEditOperationProperties]) {
        NSString *favoriteActionTitle = !self.asset.favorite ? NSLocalizedString(@"Favorite", @"") : NSLocalizedString(@"Unfavorite", @"");
        [alertController addAction:[UIAlertAction actionWithTitle:favoriteActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:self.asset];
                [request setFavorite:![self.asset isFavorite]];
            } completionHandler:^(BOOL success, NSError *error) {
                if (!success) {
                    NSLog(@"Error: %@", error);
                }
            }];
        }]];
    }
    if ([self.asset canPerformEditOperation:PHAssetEditOperationContent]) {
        if (self.asset.mediaType == PHAssetMediaTypeImage) {
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sepia", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self applyFilterWithName:@"CISepiaTone"];
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Chrome", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self applyFilterWithName:@"CIPhotoEffectChrome"];
            }]];
        }
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Revert", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:self.asset];
                [request revertAssetContentToOriginal];
            } completionHandler:^(BOOL success, NSError *error) {
                if (!success) {
                    NSLog(@"Error: %@", error);
                }
            }];
        }]];
    }
	alertController.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:alertController animated:YES completion:NULL];
	alertController.popoverPresentationController.barButtonItem = sender;
	alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
}

- (IBAction)handleTrashButtonItem:(id)sender
{
    void (^completionHandler)(BOOL, NSError *) = ^(BOOL success, NSError *error) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self navigationController] popViewControllerAnimated:YES];
            });
        } else {
            NSLog(@"Error: %@", error);
        }
    };
    
    if (self.assetCollection) {
        // Remove asset from album
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.assetCollection];
            [changeRequest removeAssets:@[self.asset]];
        } completionHandler:completionHandler];
        
    } else {
        // Delete asset from library
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest deleteAssets:@[self.asset]];
        } completionHandler:completionHandler];
        
    }
}

- (IBAction)handlePlayButtonItem:(id)sender
{
    if (!self.playerLayer) {
        [[PHImageManager defaultManager] requestAVAssetForVideo:self.asset options:nil resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!self.playerLayer) {
                    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:avAsset];
                    playerItem.audioMix = audioMix;
                    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
                    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
                    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                    
                    CALayer *layer = self.view.layer;
                    [layer addSublayer:playerLayer];
                    [playerLayer setFrame:layer.bounds];
                    [player play];
                }
            });
        }];
        
    } else {
        [self.playerLayer.player play];
    }
    
}

@end


