/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Player view controller.
*/

@import AVFoundation;
@import CoreMedia;
@import ImageIO;
@import MobileCoreServices;

#import "AAPLPlayerViewController.h"

@interface AAPLImagePickerController : UIImagePickerController

@end

@implementation AAPLImagePickerController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskLandscape;
}

@end


@interface AAPLPlayerViewController () <AVPlayerItemMetadataOutputPushDelegate>

@property (nonatomic, weak) IBOutlet UIView *playerView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *playButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *pauseButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *libraryButton;
@property (nonatomic, weak) IBOutlet UISwitch *honorTimedMetadataTracksSwitch;
@property (nonatomic, weak) IBOutlet UILabel *locationOverlayLabel;

@property (nonatomic) AVPlayerItemMetadataOutput *itemMetadataOutput;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) CALayer *facesLayer;
@property (nonatomic) BOOL honorTimedMetadataTracksDuringPlayback;
@property (nonatomic) BOOL seekToZeroBeforePlay;
@property (nonatomic) CMVideoDimensions videoDimensions;
@property (nonatomic) CGAffineTransform defaultVideoTransform;

@end

@implementation AAPLPlayerViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.honorTimedMetadataTracksSwitch addTarget:self action:@selector(toggleTMDSwitch:) forControlEvents:UIControlEventValueChanged];
	self.locationOverlayLabel.text = @"";
	self.locationOverlayLabel.textColor = [UIColor redColor];
	
	self.playButton.enabled = NO;
	self.pauseButton.enabled = NO;
	
	self.facesLayer = [CALayer layer];
	self.playerView.layer.backgroundColor = [[UIColor darkGrayColor] CGColor];
	
	dispatch_queue_t metadataQueue = dispatch_queue_create( "com.apple.metadataqueue", DISPATCH_QUEUE_SERIAL );
	self.itemMetadataOutput = [[AVPlayerItemMetadataOutput alloc] initWithIdentifiers:nil];
	[self.itemMetadataOutput setDelegate:self queue:metadataQueue];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	self.seekToZeroBeforePlay = YES;
}

- (void)toggleTMDSwitch:(id)sender
{
	if ( [sender isOn] ) {
		self.honorTimedMetadataTracksDuringPlayback = YES;
	}
	else {
		self.honorTimedMetadataTracksDuringPlayback = NO;
		[self removeAllSublayersFromLayer:self.facesLayer];
	}
}

#pragma mark Actions

- (IBAction)playButtonTapped:(id)sender
{
	if ( self.seekToZeroBeforePlay ) {
		self.seekToZeroBeforePlay = NO;
		[self.player seekToTime:kCMTimeZero];
	}
	[self.player play];
	self.playButton.enabled = NO;
	self.pauseButton.enabled = YES;
}
- (IBAction)pauseButtonTapped:(id)sender
{
	[self.player pause];
	self.playButton.enabled = YES;
	self.pauseButton.enabled = NO;
}

- (IBAction)loadMoviesFromCameraRoll:(id)sender
{
	[self.player pause];

	// Initialize UIImagePickerController to select a movie from the camera roll
	AAPLImagePickerController *videoPicker = [[AAPLImagePickerController alloc] init];
	videoPicker.delegate = self;
	videoPicker.modalPresentationStyle = UIModalPresentationPopover;
	videoPicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie];
	videoPicker.allowsEditing = NO;
	if ( UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad )	{
		videoPicker.popoverPresentationController.barButtonItem = self.libraryButton;
	}
	[self presentViewController:videoPicker animated:YES completion:nil];
}

#pragma mark Player utils

-(void)setupPlayerURL:(NSURL *)URL
{
	AVMutableComposition *mutableComposition = [AVMutableComposition composition];
	AVURLAsset *asset = [AVURLAsset URLAssetWithURL:URL options:nil];
	
	// Create a mutableComposition for all the tracks present in the asset.
	AVAssetTrack *sourceVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
	self.videoDimensions = CMVideoFormatDescriptionGetDimensions( (__bridge CMVideoFormatDescriptionRef)( sourceVideoTrack.formatDescriptions.firstObject ) );
	self.defaultVideoTransform = sourceVideoTrack.preferredTransform;
	AVAssetTrack *sourceAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
	
	AVMutableCompositionTrack *mutableCompositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	[mutableCompositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,[asset duration]) ofTrack:sourceVideoTrack atTime:kCMTimeZero error:nil];
	AVMutableCompositionTrack *mutableCompositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	[mutableCompositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,[asset duration]) ofTrack:sourceAudioTrack atTime:kCMTimeZero error:nil];

	for ( AVAssetTrack *metadataTrack in [asset tracksWithMediaType:AVMediaTypeMetadata] ) {
		if ( [self track:metadataTrack hasMetadataIdentifier:AVMetadataIdentifierQuickTimeMetadataDetectedFace] ||
			 [self track:metadataTrack hasMetadataIdentifier:AVMetadataIdentifierQuickTimeMetadataVideoOrientation] ||
			 [self track:metadataTrack hasMetadataIdentifier:AVMetadataIdentifierQuickTimeMetadataLocationISO6709] ) {
			AVMutableCompositionTrack *mutableCompositionMetadataTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeMetadata preferredTrackID:kCMPersistentTrackID_Invalid];
			[mutableCompositionMetadataTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,[asset duration]) ofTrack:metadataTrack atTime:kCMTimeZero error:nil];
		}
	}
	
	// Get an instance of AVPlayerItem for the generated mutableComposition.
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:mutableComposition];
	[playerItem addOutput:self.itemMetadataOutput];
	
	if ( self.player == nil ) {
		// Create AVPlayer with the generated instance of playerItem. Also add the facesLayer as subLayer to this playLayer.
		self.player = [AVPlayer playerWithPlayerItem:playerItem];
		self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
		self.playerLayer.transform = CATransform3DMakeAffineTransform( self.defaultVideoTransform );
		self.playerLayer.frame = self.playerView.layer.bounds;
		self.playerLayer.backgroundColor = [[UIColor darkGrayColor] CGColor];
		[self.playerLayer addSublayer:self.facesLayer];
		[self.playerView.layer addSublayer:self.playerLayer];
		[self.playerView addSubview:self.locationOverlayLabel];
		self.facesLayer.frame = self.playerLayer.videoRect;
	}
	else {
		[self.player replaceCurrentItemWithPlayerItem:playerItem];
	}
	
	// When the player item has played to its end time we'll toggle the movie controller Pause button to be the Play button
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(playerItemDidReachEnd:)
												 name:AVPlayerItemDidPlayToEndTimeNotification
											   object:self.player.currentItem];
	
	self.seekToZeroBeforePlay = NO;
}

- (void)addDidPlayToEndTimeNotificationForPlayerItem:(AVPlayerItem *)item
{
	self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
}

- (void)setupPlaybackForURL:(NSURL *)URL
{
	dispatch_async( dispatch_get_main_queue(), ^{
		if ( self.player.currentItem ) {
			[self.player.currentItem removeOutput:self.itemMetadataOutput];
		}
		[self setupPlayerURL:URL];
	} );
}

// Called when the player item has played to its end time.
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
	// After the movie has played to its end time, seek back to time zero to play it again.
	self.seekToZeroBeforePlay = YES;
	self.playButton.enabled = YES;
	self.pauseButton.enabled = NO;
	[self removeAllSublayersFromLayer:self.facesLayer];
}

#pragma mark Animation & utils

+ (void)updateAnimationForLayer:(CALayer *)layer removeAnimation:(BOOL)remove
{
	if ( remove ) {
		[layer removeAnimationForKey:@"animateOpacity"];
	}
	if ( ! [layer animationForKey:@"animateOpacity"] ) {
		layer.hidden = NO;
		CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		opacityAnimation.duration = .3f;
		opacityAnimation.repeatCount = 1.f;
		opacityAnimation.autoreverses = YES;
		opacityAnimation.fromValue = @1.f;
		[opacityAnimation setToValue:@.0f];
		[layer addAnimation:opacityAnimation forKey:@"animateOpacity"];
	}
}

- (void)removeAllSublayersFromLayer:(CALayer *)layer
{
	[CATransaction begin];
	CATransaction.disableActions = YES;
	if ( layer ) {
		NSArray *sublayers = [[layer sublayers] copy];
		for( CALayer *layer in sublayers ) {
			[layer removeFromSuperlayer];
		}
	}
	[CATransaction commit];
}

- (BOOL)track:(AVAssetTrack *)track hasMetadataIdentifier:(NSString *)metadataIdentifer
{
	CMFormatDescriptionRef desc = (__bridge CMFormatDescriptionRef)track.formatDescriptions.firstObject;
	if ( desc ) {
		NSArray *metadataIdentifiersFromTheTrack = (__bridge NSArray *)CMMetadataFormatDescriptionGetIdentifiers(desc);
		if ( [metadataIdentifiersFromTheTrack containsObject:metadataIdentifer] ) {
			return YES;
		}
	}
	return NO;
}

- (void)drawFaceMetadataRects:(NSArray *)faces
{
	dispatch_async( dispatch_get_main_queue(), ^{
		CGRect viewRect = self.playerLayer.videoRect;
		self.facesLayer.frame = viewRect;
		self.facesLayer.masksToBounds = YES;
		[self removeAllSublayersFromLayer:self.facesLayer];
		
		for ( AVMetadataObject *face in faces ) {
			CALayer *faceBox = [CALayer layer];
			CGRect faceRect = face.bounds;
			CGPoint viewFaceOrigin = CGPointMake( faceRect.origin.x * viewRect.size.width, faceRect.origin.y * viewRect.size.height );
			CGSize viewFaceSize = CGSizeMake( faceRect.size.width * viewRect.size.width, faceRect.size.height * viewRect.size.height );
			CGRect viewFaceBounds = CGRectMake( viewFaceOrigin.x, viewFaceOrigin.y, viewFaceSize.width, viewFaceSize.height );
			[CATransaction begin];
			CATransaction.disableActions = YES;
			[self.facesLayer addSublayer:faceBox];
			faceBox.masksToBounds = YES;
			faceBox.borderWidth = 2.0f;
			faceBox.borderColor = [[UIColor colorWithRed:0.30f green:0.60f blue:0.90f alpha:0.7f] CGColor];
			faceBox.cornerRadius = 5.0;
			faceBox.frame = viewFaceBounds;
			[CATransaction commit];
			[AAPLPlayerViewController updateAnimationForLayer:self.facesLayer removeAnimation:YES];
		}
	} );
}

- (BOOL)makeAffineTransform:(CGAffineTransform *)outTransform fromVideoOrientation:(NSNumber *)videoOrientation forVideoDimensions:(CMVideoDimensions)videoDimensions
{
	if ( [videoOrientation isKindOfClass:[NSNumber class]] ) {
		short voValue = videoOrientation.shortValue;
		if ( ( voValue >= 1 ) && ( voValue <= 8 ) ) {
			// Determine rotation and mirroring from tag value.
			int32_t rotationDegrees = 0;
			BOOL mirror = NO;
			switch ( voValue )
			{
				case kCGImagePropertyOrientationUp:				rotationDegrees = 0;	mirror = NO;	break;
				case kCGImagePropertyOrientationUpMirrored:		rotationDegrees = 0;	mirror = YES;	break;
				case kCGImagePropertyOrientationDown:			rotationDegrees = 180;	mirror = NO;	break;
				case kCGImagePropertyOrientationDownMirrored:	rotationDegrees = 180;	mirror = YES;	break;
				case kCGImagePropertyOrientationLeft:			rotationDegrees = 270;	mirror = NO;	break;
				case kCGImagePropertyOrientationLeftMirrored:	rotationDegrees = 90;	mirror = YES;	break;
				case kCGImagePropertyOrientationRight:			rotationDegrees = 90;	mirror = NO;	break;
				case kCGImagePropertyOrientationRightMirrored:	rotationDegrees = 270;	mirror = YES;	break;
			}
			// Build the affine transform
			CGFloat angle = 0.0;	// in radians
			CGFloat tx = 0.0;
			CGFloat ty = 0.0;
			switch ( rotationDegrees ) {
				case 90:
					angle = (CGFloat)( M_PI / 2.0 );
					tx = videoDimensions.height;
					// ty = 0.0;
					break;
					
				case 180:
					angle = (CGFloat)M_PI;
					tx = videoDimensions.width;
					ty = videoDimensions.height;
					break;
					
				case 270:
					angle = (CGFloat)( M_PI / -2.0 );
					// tx = 0.0;
					ty = videoDimensions.width;
					break;
					
				default:
					break;
			}
			// Rotate first, then translate to bring 0,0 to top left.
			if ( angle == 0.0 ) {	// and in this case, tx and ty will be 0.0
				*outTransform = CGAffineTransformIdentity;
			}
			else {
				*outTransform = CGAffineTransformMakeRotation( angle );
				*outTransform = CGAffineTransformConcat( *outTransform, CGAffineTransformMakeTranslation( tx, ty ) );
			}
			// If mirroring, flip along the proper axis
			if ( mirror ) {
				*outTransform = CGAffineTransformConcat( *outTransform, CGAffineTransformMakeScale( -1.0, 1.0 ) );
				*outTransform = CGAffineTransformConcat( *outTransform, CGAffineTransformMakeTranslation( videoDimensions.height, 0.0 ) );
			}
		}
	}
	return YES;
}

#pragma mark Orientation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

// If device is rotated manually while playing back and before the next orientation track is received, then playLayer's frame should be changed to match with the playerView bounds.
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		 self.playerLayer.frame = self.playerView.layer.bounds;
	 } completion:nil];
}

#pragma mark - Image Picker Controller Delegate

- (void)imagePickerController:(AAPLImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[self dismissViewControllerAnimated:YES completion:nil];	
	// First remove old observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
	[self setupPlaybackForURL:info[UIImagePickerControllerReferenceURL]];
	picker.delegate = nil;
	
	self.playButton.enabled = YES;
}

- (void)imagePickerControllerDidCancel:(AAPLImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:nil];
	// Make sure our playback is resumed from any interruption.
	if ( [self.player currentItem] ) {
		[self addDidPlayToEndTimeNotificationForPlayerItem:[self.player currentItem]];
	}
	picker.delegate = nil;
}

#pragma mark Metadata delegate

- (void)metadataOutput:(AVPlayerItemMetadataOutput *)output didOutputTimedMetadataGroups:(NSArray *)groups fromPlayerItemTrack:(AVPlayerItemTrack *)track
{
	for ( AVTimedMetadataGroup *group in groups ) {
		dispatch_async( dispatch_get_main_queue(), ^{

			// Sometimes the face/location track wouldn't contain any items because of scene change, we should remove previously drawn faceRects/locationOverlay in that case.
			if ( group.items.count == 0 ) {
				if ( [self track:track.assetTrack hasMetadataIdentifier:AVMetadataIdentifierQuickTimeMetadataDetectedFace] ) {
					[self removeAllSublayersFromLayer:self.facesLayer];
				} else if ( [self track:track.assetTrack hasMetadataIdentifier:AVMetadataIdentifierQuickTimeMetadataLocationISO6709] ) {
					self.locationOverlayLabel.text = @"";
				}
			}
			else {
				if ( self.honorTimedMetadataTracksDuringPlayback ) {
					NSMutableArray *faceObjects = [NSMutableArray array];
					for ( AVMetadataItem *item in group.items ) {
						// Detected face AVMetadataItems have their value property return AVMetadataFaceObjects
						if ( [item.identifier isEqualToString:AVMetadataIdentifierQuickTimeMetadataDetectedFace] ) {
							[faceObjects addObject:item.value];
						}
						else if ( [item.identifier isEqualToString:AVMetadataIdentifierQuickTimeMetadataVideoOrientation] &&
								  [item.dataType isEqualToString:(NSString *)kCMMetadataBaseDataType_SInt16] ) {
							CGAffineTransform orientationTransform = CGAffineTransformIdentity;
							if ( ! [self makeAffineTransform:&orientationTransform fromVideoOrientation:(NSNumber *)item.value forVideoDimensions:self.videoDimensions] ) {
								orientationTransform = self.defaultVideoTransform;
							}
							CATransform3D rotationTransform = CATransform3DMakeAffineTransform(orientationTransform);
							// Remove faceBoxes before applying trasform and then re-draw them as we get new face coordinates.
							[self removeAllSublayersFromLayer:self.facesLayer];
							self.playerLayer.transform = rotationTransform;
							self.playerLayer.frame = self.playerView.layer.bounds;
						}
						else if ( [item.identifier isEqual:AVMetadataIdentifierQuickTimeMetadataLocationISO6709] &&
								  [item.dataType isEqualToString:(__bridge id)kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709] ) {
							self.locationOverlayLabel.text = (NSString *)item.value;
						}
					}
					if ( faceObjects.count ) {
						[self drawFaceMetadataRects:faceObjects];
					}
				}
			}
		} );
	}
}

@end
