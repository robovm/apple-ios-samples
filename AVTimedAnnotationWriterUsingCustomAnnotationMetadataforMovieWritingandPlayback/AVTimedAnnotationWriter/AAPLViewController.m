/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Main view controller which setups playback and also lets a user write circle and text annotation through gestures to a movie file.
  
 */

#import "AAPLViewController.h"
#import "AAPLTimedAnnotationWriter.h"
#import "AAPLPlayerViewController.h"
#import "AAPLPlayerView.h"

#import <CoreMedia/CMMetadata.h>

#define CIRCLE_LAYER_DEFAULT_RADIUS 100.0

static NSString* const AAPLViewControllerStatusObservationContext = @"AAPLViewControllerStatusObservationContext";
static NSString* const AAPLViewControllerRateObservationContext = @"AAPLViewControllerRateObservationContext";

@interface AAPLViewController ()
{
	BOOL			_playing;
	BOOL			_seekToZeroBeforePlaying;
}

// Playback state
@property AVAsset						*asset;
@property AVPlayer						*player;
@property AVPlayerItem					*playerItem;
@property CMTime						previousTime;

// Annotation state
@property CAShapeLayer					*circleLayer;
@property UITextField					*annotationText;
@property CGPoint						circleCenter;
@property CGFloat						circleRadius;
@property NSMutableArray				*metadataGroups;

// IBOutlets
@property IBOutlet AAPLPlayerView			*playerView;
@property IBOutlet UIToolbar				*toolbar;
@property IBOutlet UIBarButtonItem			*playPauseButton;
@property IBOutlet UIBarButtonItem			*exportButton;
@property IBOutlet UITapGestureRecognizer	*oneFingerTapRecognizer;
@property IBOutlet UITapGestureRecognizer	*twoFingersTapRecognizer;

// IBActions
- (IBAction)togglePlayPause:(id)sender;
- (IBAction)handleOneFingerTapFrom:(UITapGestureRecognizer *)recognizer;
- (IBAction)handleTwoFingersTapFrom:(UITapGestureRecognizer *)recognizer;
- (IBAction)handlePinchFrom:(UIPinchGestureRecognizer *)recognizer;
- (IBAction)handlePanFrom:(UIPanGestureRecognizer *)recognizer;

@end

@implementation AAPLViewController

#pragma mark - View Loading

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.oneFingerTapRecognizer requireGestureRecognizerToFail:self.twoFingersTapRecognizer];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (!self.player)
	{
		// Set up player object for playback
		self.player = [[AVPlayer alloc] init];
		[self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:(__bridge void *)(AAPLViewControllerRateObservationContext)];
		[self.playerView setPlayer:self.player];
		_seekToZeroBeforePlaying = NO;
		
		self.metadataGroups = [NSMutableArray array];
		self.asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sample" ofType:@"m4v"]]];
		// Create player item with asset and set it up for playback
		[self createPlayerItemWithAsset:self.asset];
		
		// Setup for annotation writing
		self.previousTime = kCMTimeNegativeInfinity;
		self.circleRadius = CIRCLE_LAYER_DEFAULT_RADIUS;
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[self.player pause];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"Export"])
	{
		NSURL *url = [self writeToMovie];
		
		// Setup player controller with the url which is the outcome of export
		AAPLPlayerViewController *playerController = (AAPLPlayerViewController *)((UINavigationController *)segue.destinationViewController).topViewController;
		[playerController loadView];
		[playerController setupPlaybackWithURL:url];
	}
}

#pragma mark - Playback setup

- (void)createPlayerItemWithAsset:(AVAsset *)asset
{
	if (self.player == nil)
		return;
	
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
	
	if (self.playerItem != playerItem)
	{
		if (self.playerItem)
		{
			[self.playerItem removeObserver:self forKeyPath:@"status"];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
		}
		
		self.playerItem = playerItem;
		
		if (self.playerItem)
		{
			// Observe the player item "status" key to determine when it is ready to play
			[self.playerItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) context:(__bridge void *)(AAPLViewControllerStatusObservationContext)];
			
			// When the player item has played to its end time we'll set a flag
			// so that the next time the play method is issued the player will
			// be reset to time zero first.
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
		}
		
		[self.player replaceCurrentItemWithPlayerItem:playerItem];
	}
}

#pragma mark - KVO callback

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == (__bridge void *)(AAPLViewControllerRateObservationContext))
	{
		float newRate = [change[NSKeyValueChangeNewKey] floatValue];
		NSNumber *oldRateNum = change[NSKeyValueChangeOldKey];
		if ([oldRateNum isKindOfClass:[NSNumber class]] && newRate != [oldRateNum floatValue])
		{
			_playing = (newRate != 0.f);
			[self updatePlayPauseButton];
		}
	}
	else if (context == (__bridge void *)(AAPLViewControllerStatusObservationContext))
	{
		AVPlayerItem *playerItem = (AVPlayerItem *)object;
		if (playerItem.status == AVPlayerItemStatusFailed)
		{
			[self reportError:playerItem.error];
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - Utilities

- (void)updatePlayPauseButton
{
	UIBarButtonSystemItem style = _playing ? UIBarButtonSystemItemPause : UIBarButtonSystemItemPlay;
	UIBarButtonItem *newPlayPauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:style target:self action:@selector(togglePlayPause:)];
	
	NSMutableArray *items = [NSMutableArray arrayWithArray:self.toolbar.items];
	[items replaceObjectAtIndex:[items indexOfObject:self.playPauseButton] withObject:newPlayPauseButton];
	[self.toolbar setItems:items];
	
	self.playPauseButton = newPlayPauseButton;
}

// This method is called when the user first tries to add a circle annotation as well as when the user is resize the circle radius via a pinch gesture
- (void)updateCircleLayerWithCenter:(CGPoint)center radius:(float)radius
{
	self.circleRadius = radius;
	
	// Create CAShapeLayer which has gray rectangle with 0.5 opacity and circle (focus ring) of radius with 0 opacity
	// This shape layer lets the user draw a circle annotation and resize before writing it out as metadata to the movie
	UIBezierPath *grayPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(-2000, -2000, self.playerView.bounds.size.width * 5, self.playerView.bounds.size.height * 5) cornerRadius:0];
	UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(center.x - radius, center.y - radius, 2.0*radius, 2.0*radius) cornerRadius:radius];
	[grayPath appendPath:circlePath];
	
	// This will fill the rectangle except the inside of the circle
	[grayPath setUsesEvenOddFillRule:YES];
	
	CAShapeLayer *fillLayer = [CAShapeLayer layer];
	fillLayer.path = grayPath.CGPath;
	fillLayer.fillRule = kCAFillRuleEvenOdd;
	fillLayer.fillColor = [UIColor blackColor].CGColor;
	fillLayer.strokeColor = [UIColor redColor].CGColor;
	fillLayer.lineWidth = 5;
	fillLayer.opacity = 0.5;
	
	[self.circleLayer removeFromSuperlayer];
	self.circleLayer = fillLayer;
	
	// Add circle annotation to the player view
	[self.playerView.layer addSublayer:self.circleLayer];
	
	// Update text field location based on the resized circle
	[self updateTextFieldAt:center radius:radius];
}

// This method is called when the user first tries to add a circle annotation and text comment as well as when the user is resize the circle radius via a pinch gesture
- (void)updateTextFieldAt:(CGPoint)center radius:(float)radius
{
	UITextField *newAnnotationText = [[UITextField alloc] initWithFrame:CGRectMake(center.x + radius, center.y - radius, 200, 40)];
	newAnnotationText.text= @"Comment";
	newAnnotationText.textColor = [UIColor whiteColor];
	newAnnotationText.backgroundColor = [UIColor redColor];
	newAnnotationText.borderStyle = UITextBorderStyleRoundedRect;
	newAnnotationText.textAlignment = NSTextAlignmentCenter;
	
	// Add the annotation text to playerview
	[self.annotationText removeFromSuperview];
	self.annotationText = newAnnotationText;
	[self.playerView addSubview:self.annotationText];
}

// Called when the player item has played to its end time
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
	// After the movie has played to its end time, seek back to time zero to play it again.
	_seekToZeroBeforePlaying = YES;
}

// This method creates the timed metadata groups with circle center, radius and text to write out to a movie file
- (void)addMetadataForCirclePosition:(CGPoint)circleCenter
{
	CMTime currentTime = [self.player currentTime];
	
	// Circle coordinate item
	AVMutableMetadataItem *coordinateItem = [AVMutableMetadataItem metadataItem];
	coordinateItem.identifier = AAPLTimedAnnotationWriterCircleCenterCoordinateIdentifier;
	coordinateItem.dataType = (__bridge NSString *)kCMMetadataBaseDataType_PointF32;
	coordinateItem.value = [NSValue valueWithCGPoint:circleCenter];
	
	// Circle radius item
	AVMutableMetadataItem *radiusItem = [AVMutableMetadataItem metadataItem];
	radiusItem.identifier = AAPLTimedAnnotationWriterCircleRadiusIdentifier;
	radiusItem.dataType = (__bridge NSString *)kCMMetadataBaseDataType_Float64;
	radiusItem.value = [NSNumber numberWithFloat:self.circleRadius];
	
	// Annotation text item
	AVMutableMetadataItem *textItem = [AVMutableMetadataItem metadataItem];
	textItem.identifier = AAPLTimedAnnotationWriterCommentFieldIdentifier;
	textItem.dataType = (__bridge NSString *)kCMMetadataBaseDataType_UTF8;
	textItem.value = self.annotationText.text;
	
	// All timed metadata groups to be appended to AVAssetWriterInputMetadataAdaptor must have unique time ranges, make sure we don't append groups with the same current time
	if (CMTimeCompare(currentTime, self.previousTime) > 0)
	{
		AVTimedMetadataGroup *group = [[AVTimedMetadataGroup alloc] initWithItems:@[coordinateItem, radiusItem, textItem] timeRange:CMTimeRangeMake(currentTime, kCMTimeInvalid)];
		[self.metadataGroups addObject:group];
		self.previousTime = currentTime;
	}
}
		 
- (NSURL *)writeToMovie
{
	[self.player pause];

	// Write out original asset + timed metadata to a movie
	AAPLTimedAnnotationWriter *writer = [[AAPLTimedAnnotationWriter alloc] initWithAsset:self.asset];
	[writer writeMetadataGroups:self.metadataGroups];
	return writer.outputURL;
}
		 
- (void)reportError:(NSError *)error
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (error)
		{
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:error.localizedDescription
																message:error.localizedRecoverySuggestion
															   delegate:nil
													  cancelButtonTitle:NSLocalizedString(@"OK", nil)
													  otherButtonTitles:nil];
			
			[alertView show];
		}
	});
}

#pragma mark - IBActions

- (IBAction)togglePlayPause:(id)sender
{
	_playing = !_playing;
	if ( _playing )
	{
		if ( _seekToZeroBeforePlaying )
		{
			[self.player seekToTime:kCMTimeZero];
			_seekToZeroBeforePlaying = NO;
		}
		[self.player play];
	}
	else
	{
		[self.player pause];
	}
}

// One finger tap begins playback and starts recording circle location over time
- (IBAction)handleOneFingerTapFrom:(UITapGestureRecognizer *)recognizer
{
	[self.player play];
	
	// Add the first circle position as metadata
	if (self.circleLayer)
	{
		self.circleLayer.fillColor = [UIColor clearColor].CGColor;
		self.circleLayer.opacity = 1.0;
		
		[self addMetadataForCirclePosition:self.circleCenter];
	}
}

// Two finger tap, adds circle annotation, which can then be resized and when ready use one finger tap to resume playback
- (IBAction)handleTwoFingersTapFrom:(UITapGestureRecognizer *)recognizer
{
	if (!self.circleLayer || self.circleLayer.hidden)
	{
		CGPoint tapPoint = [recognizer locationInView:self.playerView];
		self.circleCenter = tapPoint;
		// Set up the shape of the circle
		[self updateCircleLayerWithCenter:tapPoint radius:self.circleRadius];
	}
}

// Pinch is used to resize circle only when playback is paused
- (IBAction)handlePinchFrom:(UIPinchGestureRecognizer *)recognizer
{
	if (!_playing)
	{
		[self updateCircleLayerWithCenter:self.circleCenter radius:(CIRCLE_LAYER_DEFAULT_RADIUS * recognizer.scale)];
	}
}

// Pan is used to move the circle and record circle center updates as playback progresses
- (IBAction)handlePanFrom:(UIPanGestureRecognizer *)recognizer
{
	CGPoint translation = [recognizer translationInView:self.playerView];
	
	// Move the circle layer and annotation text view
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	self.circleLayer.transform = CATransform3DMakeTranslation(translation.x, translation.y, 0);
	self.annotationText.transform = CGAffineTransformMakeTranslation(translation.x, translation.y);
	[CATransaction commit];
	
	// Add updated coordinates as metadata to be written out to movie file
	CGPoint updatedCenter = CGPointMake(self.circleCenter.x + translation.x, self.circleCenter.y + translation.y);
	[self addMetadataForCirclePosition:updatedCenter];
}

@end
