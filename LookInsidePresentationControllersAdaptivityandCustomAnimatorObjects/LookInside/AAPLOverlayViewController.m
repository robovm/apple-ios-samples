/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  AAPLOverlayViewController implementation.
  
 */

#import "AAPLOverlayViewController.h"

@interface AAPLOverlayViewController ()
@property (nonatomic, strong) CIContext *context;
@property (nonatomic, strong) CIImage *baseCIImage;
@property (nonatomic, strong) CIFilter *colorControlsFilter;
@property (nonatomic, strong) CIFilter *hueAdjustFilter;
@end

@implementation AAPLOverlayViewController
{
    dispatch_queue_t processingQueue;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self)
    {
        // To indicate to the system that we have a custom presentation controller, use UIModalPresentationCustom as our modalPresentationStyle
        [self setModalPresentationStyle:UIModalPresentationCustom];
        [self setup];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set up our foreground and background views
    _foregroundContentView = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect effectForBlurEffect:[self blurEffect]]];
    _backgroundView = [[UIVisualEffectView alloc] initWithEffect:[self blurEffect]];

    _foregroundContentScrollView = [[UIScrollView alloc] initWithFrame:[[self view] frame]];

    [self configureViews];
}

- (void)configureCIObjects {
    // Configure the objects we'll need for our Core Image filter
    if (!self.context) {
        self.context = [CIContext contextWithOptions:nil];
    }
    
    self.baseCIImage = [CIImage imageWithCGImage:[[[self photoView] image] CGImage]];
}

- (void)setPhotoView:(AAPLPhotoCollectionViewCell *)photoView {
    if ([self photoView] != photoView) {
        _photoView = photoView;
        
        [self configureCIObjects];
    }
}

- (AAPLPhotoCollectionViewCell *)photoView
{
    return _photoView;
}

- (void)sliderChanged:(id)sender
{
    CGFloat hue = [[self hueSlider] value];
    CGFloat saturation = [[self saturationSlider] value];
    CGFloat brightness = [[self brightnessSlider] value];

    // Update labels

    [[self hueLabel] setText:[NSString stringWithFormat:NSLocalizedString(@"Hue: %f", @"Hue label format."), hue]];
    [[self saturationLabel] setText:[NSString stringWithFormat:NSLocalizedString(@"Saturation: %f", @"Saturation label format."), saturation]];
    [[self brightnessLabel] setText:[NSString stringWithFormat:NSLocalizedString(@"Brightness: %f", @"Brightness label format."), brightness]];

    // Apply effects to image
    
    dispatch_async(processingQueue, ^{
        if (!self.colorControlsFilter) {
            self.colorControlsFilter = [CIFilter filterWithName:@"CIColorControls"];
        }
        [self.colorControlsFilter setValue:self.baseCIImage forKey:kCIInputImageKey];
        [self.colorControlsFilter setValue:@(saturation) forKey:@"inputSaturation"];
        [self.colorControlsFilter setValue:@(brightness) forKey:@"inputBrightness"];
        
        CIImage *coreImageOutputImage = [self.colorControlsFilter valueForKey:kCIOutputImageKey];
        
        if (!self.hueAdjustFilter) {
            self.hueAdjustFilter = [CIFilter filterWithName:@"CIHueAdjust"];
        }
        [self.hueAdjustFilter setValue:coreImageOutputImage forKey:kCIInputImageKey];
        [self.hueAdjustFilter setValue:@(hue) forKey:@"inputAngle"];
        
        coreImageOutputImage = [self.hueAdjustFilter valueForKey:kCIOutputImageKey];
        
        CGImageRef cgImage = [self.context createCGImage:coreImageOutputImage fromRect:CGRectMake(0,0,[[[self photoView] image] size].width, [[[self photoView] image] size].height)];
        UIImage *image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self imageView] setImage:image];
        });
    });
    
}

- (void)savePushed:(id)sender
{
    // When saving, set our processed image on the photo view, and dismiss ourselves
    [[self photoView] setImage:[[self imageView] image]];
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:NULL];
}

- (UISlider *)configuredOverlaySlider
{
    UISlider *slider = [[UISlider alloc] init];
    [slider setTranslatesAutoresizingMaskIntoConstraints:NO];
    [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [slider setContinuous:NO];
    return slider;
}

- (void)setup
{
    // Set up our image view, blur effect, and image processing queue
    _imageView = [[UIImageView alloc] init];
    [[self imageView] setContentMode:UIViewContentModeScaleAspectFit];
    [[self imageView] setTranslatesAutoresizingMaskIntoConstraints:NO];
    _blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    
    processingQueue = dispatch_queue_create("image processing queue", DISPATCH_QUEUE_SERIAL);
}

- (void)configureViews
{
    // Set up our foreground labels, sliders and other views
    [[self imageView] setImage:[[self photoView] image]];
    [[self view] setBackgroundColor:[UIColor clearColor]];

    [[self backgroundView] setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[self foregroundContentScrollView] setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[self foregroundContentView] setTranslatesAutoresizingMaskIntoConstraints:NO];
    _hueLabel = [[AAPLOverlayVibrantLabel alloc] init];
    _hueSlider = [self configuredOverlaySlider];
    [[self hueSlider] setMaximumValue:10.0];

    _saturationLabel = [[AAPLOverlayVibrantLabel alloc] init];
    _saturationSlider = [self configuredOverlaySlider];
    [[self saturationSlider] setValue:1.0];
    [[self saturationSlider] setMaximumValue:2.0];
    
    _brightnessLabel = [[AAPLOverlayVibrantLabel alloc] init];
    _brightnessSlider = [self configuredOverlaySlider];
    [[self brightnessSlider] setMinimumValue:-0.5];
    [[self brightnessSlider] setMaximumValue:0.5];

    _saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [[self saveButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[self saveButton] setTitle:NSLocalizedString(@"Save", @"Save button title.") forState:UIControlStateNormal];
    [[[self saveButton] titleLabel] setFont:[UIFont systemFontOfSize:32.0]];
    [[self saveButton] addTarget:self action:@selector(savePushed:) forControlEvents:UIControlEventTouchUpInside];
    
    [[self view] addSubview:[self backgroundView]];
    [[self view] addSubview:[self foregroundContentScrollView]];

    [[self foregroundContentScrollView] addSubview:[self foregroundContentView]];

    [[[self foregroundContentView] contentView] addSubview:[self hueLabel]];
    [[[self foregroundContentView] contentView] addSubview:[self hueSlider]];

    [[[self foregroundContentView] contentView] addSubview:[self saturationLabel]];
    [[[self foregroundContentView] contentView] addSubview:[self saturationSlider]];

    [[[self foregroundContentView] contentView] addSubview:[self brightnessLabel]];
    [[[self foregroundContentView] contentView] addSubview:[self brightnessSlider]];

    [[[self foregroundContentView] contentView] addSubview:[self saveButton]];

    [[self foregroundContentScrollView] addSubview:[self imageView]];
    
    // Add constraints

    NSDictionary* views = @{
                 @"backgroundView" : [self backgroundView],
    @"foregroundContentScrollView" : [self foregroundContentScrollView],
          @"foregroundContentView" : [self foregroundContentView],
                       @"hueLabel" : [self hueLabel],
                      @"hueSlider" : [self hueSlider],
                @"saturationLabel" : [self saturationLabel],
               @"saturationSlider" : [self saturationSlider],
                @"brightnessLabel" : [self brightnessLabel],
               @"brightnessSlider" : [self brightnessSlider],
                     @"saveButton" : [self saveButton],
                      @"imageView" : [self imageView]
    };
    
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[backgroundView]|" options:0 metrics:nil views:views]];
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backgroundView]|" options:0 metrics:nil views:views]];

    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[foregroundContentScrollView]|" options:0 metrics:nil views:views]];
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[foregroundContentScrollView]|" options:0 metrics:nil views:views]];
    
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[foregroundContentView]|" options:0 metrics:nil views:views]];
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[foregroundContentView]|" options:0 metrics:nil views:views]];
    
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[hueLabel]-|" options:0 metrics:nil views:views]];
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[hueSlider]-|" options:0 metrics:nil views:views]];
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[saturationLabel]-|" options:0 metrics:nil views:views]];
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[saturationSlider]-|" options:0 metrics:nil views:views]];
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[brightnessLabel]-|" options:0 metrics:nil views:views]];
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[brightnessSlider]-|" options:0 metrics:nil views:views]];
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[saveButton]-|" options:0 metrics:nil views:views]];
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView(==foregroundContentScrollView)]|" options:0 metrics:nil views:views]];
    
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=30)-[hueLabel]-[hueSlider]-[saturationLabel]-[saturationSlider]-[brightnessLabel]-[brightnessSlider]-[saveButton]-(>=10)-[imageView(==200)]|" options:0 metrics:nil views:views]];
    
    [self sliderChanged:nil];
}

@end

@implementation AAPLOverlayVibrantLabel

// This is a simple UILabel subclass to change the text color based on the tint
// color of the label

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    
    return self;
}

- (void)tintColorDidChange
{
    [self setTextColor:[self tintColor]];
}

@end
