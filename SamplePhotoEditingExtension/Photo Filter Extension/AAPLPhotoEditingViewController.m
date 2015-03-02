/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The view controller of the photo editing extension.
  
 */

#import "AAPLPhotoEditingViewController.h"

#import "AAPLAVReaderWriter.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>


NSString *const kFilterInfoFilterNameKey = @"filterName";
NSString *const kFilterInfoDisplayNameKey = @"displayName";
NSString *const kFilterInfoPreviewImageKey = @"previewImage";


@interface AAPLPhotoEditingViewController () <PHContentEditingController, UICollectionViewDataSource, UICollectionViewDelegate, AAPLAVReaderWriterAdjustDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UIImageView *filterPreviewView;
@property (nonatomic, weak) IBOutlet UIImageView *backgroundImageView;

@property (nonatomic, strong) NSArray *availableFilterInfos;
@property (nonatomic, strong) NSString *selectedFilterName;
@property (nonatomic, strong) NSString *initialFilterName;

@property (nonatomic, strong) UIImage *inputImage;
@property (nonatomic, strong) CIFilter *ciFilter;
@property (nonatomic, strong) CIContext *ciContext;

@property (nonatomic, strong) PHContentEditingInput *contentEditingInput;

@end


@implementation AAPLPhotoEditingViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup collection view
    self.collectionView.alwaysBounceHorizontal = YES;
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.allowsSelection = YES;
    
    // Load the available filters
    NSString *plist = [[NSBundle mainBundle] pathForResource:@"Filters" ofType:@"plist"];
    self.availableFilterInfos = [NSArray arrayWithContentsOfFile:plist];
    
    self.ciContext = [CIContext contextWithOptions:nil];
    
    // Add the background image and UIEffectView for the blur
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    [effectView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view insertSubview:effectView aboveSubview:self.backgroundImageView];
    
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[effectView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(effectView)];
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[effectView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(effectView)];
    [self.view addConstraints:verticalConstraints];
    [self.view addConstraints:horizontalConstraints];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Update the selection UI
    NSInteger item = [self.availableFilterInfos indexOfObjectPassingTest:^BOOL(NSDictionary *filterInfo, NSUInteger idx, BOOL *stop) {
        return [filterInfo[kFilterInfoFilterNameKey] isEqualToString:self.selectedFilterName];
    }];
    if (item != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO
                                    scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        [self updateSelectionForCell:[self.collectionView cellForItemAtIndexPath:indexPath]];
    }
}


#pragma mark - PHContentEditingController

- (BOOL)canHandleAdjustmentData:(PHAdjustmentData *)adjustmentData {
    BOOL result = [adjustmentData.formatIdentifier isEqualToString:@"com.example.apple-samplecode.photofilter"];
    result &= [adjustmentData.formatVersion isEqualToString:@"1.0"];
    return result;
}

- (void)startContentEditingWithInput:(PHContentEditingInput *)contentEditingInput placeholderImage:(UIImage *)placeholderImage {
    self.contentEditingInput = contentEditingInput;
    
    // Load input image
    switch (self.contentEditingInput.mediaType) {
        case PHAssetMediaTypeImage:
            self.inputImage = self.contentEditingInput.displaySizeImage;
            break;
            
        case PHAssetMediaTypeVideo:
            self.inputImage = [self imageForAVAsset:self.contentEditingInput.avAsset atTime:0.0];
            break;
            
        default:
            break;
    }
    
    // Load adjustment data, if any
    @try {
        PHAdjustmentData *adjustmentData = self.contentEditingInput.adjustmentData;
        if (adjustmentData) {
            self.selectedFilterName = [NSKeyedUnarchiver unarchiveObjectWithData:adjustmentData.data];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception decoding adjustment data: %@", exception);
    }
    if (!self.selectedFilterName) {
        NSString *defaultFilterName = @"CISepiaTone";
        self.selectedFilterName = defaultFilterName;
    }
    self.initialFilterName = self.selectedFilterName;
    
    // Update filter and background image
    [self updateFilter];
    [self updateFilterPreview];
    self.backgroundImageView.image = placeholderImage;
}

- (void)finishContentEditingWithCompletionHandler:(void (^)(PHContentEditingOutput *))completionHandler {
    PHContentEditingOutput *contentEditingOutput = [[PHContentEditingOutput alloc] initWithContentEditingInput:self.contentEditingInput];
    
    // Adjustment data
    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:self.selectedFilterName];
    PHAdjustmentData *adjustmentData = [[PHAdjustmentData alloc] initWithFormatIdentifier:@"com.example.apple-samplecode.photofilter"
                                                                            formatVersion:@"1.0"
                                                                                     data:archivedData];
    contentEditingOutput.adjustmentData = adjustmentData;
    
    switch (self.contentEditingInput.mediaType) {
        case PHAssetMediaTypeImage: {
            // Get full size image
            NSURL *url = self.contentEditingInput.fullSizeImageURL;
            int orientation = self.contentEditingInput.fullSizeImageOrientation;
            
            // Generate rendered JPEG data
            UIImage *image = [UIImage imageWithContentsOfFile:url.path];
            image = [self transformedImage:image withOrientation:orientation usingFilter:self.ciFilter];
            NSData *renderedJPEGData = UIImageJPEGRepresentation(image, 0.9f);
            
            // Save JPEG data
            NSError *error = nil;
            BOOL success = [renderedJPEGData writeToURL:contentEditingOutput.renderedContentURL options:NSDataWritingAtomic error:&error];
            if (success) {
                completionHandler(contentEditingOutput);
            } else {
                NSLog(@"An error occured: %@", error);
                completionHandler(nil);
            }
            break;
        }
            
        case PHAssetMediaTypeVideo: {
            // Get AV asset
            AAPLAVReaderWriter *avReaderWriter = [[AAPLAVReaderWriter alloc] initWithAsset:self.contentEditingInput.avAsset];
            avReaderWriter.delegate = self;
            
            // Save filtered video
            [avReaderWriter writeToURL:contentEditingOutput.renderedContentURL
                              progress:^(float progress) {
                              }
                            completion:^(NSError *error) {
                                if (!error) {
                                    completionHandler(contentEditingOutput);
                                } else {
                                    NSLog(@"An error occured: %@", error);
                                    completionHandler(nil);
                                }
                            }];
            break;
        }
            
        default:
            break;
    }
    
}

- (void)cancelContentEditing {
    // Handle cancellation
}

- (BOOL)shouldShowCancelConfirmation {
    BOOL shouldShowCancelConfirmation = NO;
    
    if (![self.selectedFilterName isEqualToString:self.initialFilterName]) {
        shouldShowCancelConfirmation = YES;
    }
    
    return shouldShowCancelConfirmation;
}

#pragma mark - Image Filtering

- (void)updateFilter {
    self.ciFilter = [CIFilter filterWithName:self.selectedFilterName];
    
    CIImage *inputImage = [CIImage imageWithCGImage:self.inputImage.CGImage];
    int orientation = [self orientationFromImageOrientation:self.inputImage.imageOrientation];
    inputImage = [inputImage imageByApplyingOrientation:orientation];
    
    [self.ciFilter setValue:inputImage forKey:kCIInputImageKey];
}

- (void)updateFilterPreview {
    CIImage *outputImage = self.ciFilter.outputImage;
    
    CGImageRef cgImage = [self.ciContext createCGImage:outputImage fromRect:outputImage.extent];
    UIImage *transformedImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    self.filterPreviewView.image = transformedImage;
}

- (UIImage *)transformedImage:(UIImage *)image withOrientation:(int)orientation usingFilter:(CIFilter *)filter {
    CIImage *inputImage = [CIImage imageWithCGImage:image.CGImage];
    inputImage = [inputImage imageByApplyingOrientation:orientation];
    
    [self.ciFilter setValue:inputImage forKey:kCIInputImageKey];
    CIImage *outputImage = [self.ciFilter outputImage];
    
    CGImageRef cgImage = [self.ciContext createCGImage:outputImage fromRect:outputImage.extent];
    UIImage *transformedImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return transformedImage;
}

#pragma mark - AAPLAVReaderWriterAdjustDelegate (Video Filtering)

- (void)adjustPixelBuffer:(CVPixelBufferRef)inputBuffer toOutputBuffer:(CVPixelBufferRef)outputBuffer {
    CIImage *img = [CIImage imageWithCVPixelBuffer:inputBuffer];
    
    [self.ciFilter setValue:img forKey:kCIInputImageKey];
    img = self.ciFilter.outputImage;
    
    [self.ciContext render:img toCVPixelBuffer:outputBuffer];
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.availableFilterInfos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *filterInfo = self.availableFilterInfos[indexPath.item];
    NSString *displayName = filterInfo[kFilterInfoDisplayNameKey];
    NSString *previewImageName = filterInfo[kFilterInfoPreviewImageKey];
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoFilterCell" forIndexPath:indexPath];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:999];
    imageView.image = [UIImage imageNamed:previewImageName];
    
    UILabel *label = (UILabel *)[cell viewWithTag:998];
    label.text = displayName;
    
    [self updateSelectionForCell:cell];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedFilterName = self.availableFilterInfos[indexPath.item][kFilterInfoFilterNameKey];
    [self updateFilter];
    
    [self updateSelectionForCell:[collectionView cellForItemAtIndexPath:indexPath]];
    
    [self updateFilterPreview];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self updateSelectionForCell:[collectionView cellForItemAtIndexPath:indexPath]];
}

- (void)updateSelectionForCell:(UICollectionViewCell *)cell {
    BOOL isSelected = cell.selected;
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:999];
    imageView.layer.borderColor = self.view.tintColor.CGColor;
    imageView.layer.borderWidth = isSelected ? 2.0 : 0.0;
    
    UILabel *label = (UILabel *)[cell viewWithTag:998];
    label.textColor = isSelected ? self.view.tintColor : [UIColor whiteColor];
}

#pragma mark - Utilities

// Returns the EXIF/TIFF orientation value corresponding to the given UIImageOrientation value.
- (int)orientationFromImageOrientation:(UIImageOrientation)imageOrientation {
    int orientation = 0;
    switch (imageOrientation) {
        case UIImageOrientationUp:            orientation = 1; break;
        case UIImageOrientationDown:          orientation = 3; break;
        case UIImageOrientationLeft:          orientation = 8; break;
        case UIImageOrientationRight:         orientation = 6; break;
        case UIImageOrientationUpMirrored:    orientation = 2; break;
        case UIImageOrientationDownMirrored:  orientation = 4; break;
        case UIImageOrientationLeftMirrored:  orientation = 5; break;
        case UIImageOrientationRightMirrored: orientation = 7; break;
        default: break;
    }
    return orientation;
}

- (UIImage *)imageForAVAsset:(AVAsset *)avAsset atTime:(NSTimeInterval)time {
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:avAsset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CGImageRef posterImage = [imageGenerator copyCGImageAtTime:CMTimeMakeWithSeconds(time, 100) actualTime:NULL error:NULL];
    UIImage *image = [UIImage imageWithCGImage:posterImage];
    CGImageRelease(posterImage);
    return image;
}

@end
