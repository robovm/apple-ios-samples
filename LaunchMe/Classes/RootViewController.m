/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The application's root view controller.
*/


#import "RootViewController.h"

@interface RootViewController ()
/// Things for IB
@property (nonatomic, weak) IBOutlet UISlider *redSlider;
@property (nonatomic, weak) IBOutlet UISlider *greenSlider;
@property (nonatomic, weak) IBOutlet UISlider *blueSlider;
@property (nonatomic, weak) IBOutlet UITextView *urlField;
@property (nonatomic, weak) IBOutlet UIView *colorView;
@end


@implementation RootViewController

// -------------------------------------------------------------------------------
//	updateWithColor:
//  Update the interface to display aColor.  This includes modifying colorView
//  to show aColor, moving the red, green, and blue sliders to match the R, G, and
//  B components of aColor, and updating urlLabel to display the corresponding
//  URL for aColor.
// -------------------------------------------------------------------------------
- (void)updateWithColor:(UIColor*)aColor
{
    // There is a possibility that -getRed:green:blue:alpha: could fail if aColor
    // is not in a compatible color space.  In such a case, the arguments are not
    // modified.  Having default values will allow for a more graceful failure
    // than picking up whatever is currently on the stack.
    CGFloat red = 0.0f;
    CGFloat green = 0.0f;
    CGFloat blue = 0.0f;
    CGFloat alpha = 0.0f;
    
    if ([aColor getRed:&red green:&green blue:&blue alpha:&alpha] == NO)
    {
        // While setting default values for red, green, blue and alpha
        // guards against undefined results if -getRed:green:blue:alpha:
        // fails, aColor will be assigned as the backgroundColor of
        // colorView a few lines down.  Initialize aColor to the black
        // color so it matches the color code that will be displayed in
        // the urlLabel.
        aColor = [UIColor blackColor];
        
    }
    
    self.redSlider.value = red;
    self.greenSlider.value = green;
    self.blueSlider.value = blue;
    
    self.colorView.backgroundColor = aColor;
    
    // Construct the URL for the specified color.  This URL allows another app
    // to start LauncMe with the specific color displayed initially.
    // When entering a custom url into Safari's address field, Safari may interpret
    // the url as a search query unless you include "//" after the url scheme.
    self.urlField.text = [NSString stringWithFormat:@"launchme://#%.2x%.2x%.2x",
                          (unsigned char)(red * 255),
                          (unsigned char)(green * 255),
                          (unsigned char)(blue * 255)];
    
    self.urlFieldHeader.text = @"Tap to select the URL";
}

// -------------------------------------------------------------------------------
//	setSelectedColor:
//  Custom implementation of the setter for the selectedColor property.
// -------------------------------------------------------------------------------
- (void)setSelectedColor:(UIColor *)selectedColor
{
    if (selectedColor != _selectedColor)
    {
        _selectedColor = selectedColor;
        [self updateWithColor:_selectedColor];
    }
}

#pragma mark - View Lifecycle

// -------------------------------------------------------------------------------
//	viewDidLoad
// -------------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // The AppDelegate may have assigned a color to selectedColor that should
    // be the color displayed initially.  This would have occurred before the
    // view was actually loaded meaning that while -updateWithColor was executed,
    // it had no effect.  The solution is to call it again here now that there is
    // a UI to update.
    [self updateWithColor:_selectedColor];
}

#pragma mark - Actions

// -------------------------------------------------------------------------------
//	touchesEnded:withEvent:
//  Deselects the text in the urlField if the user taps in the white space
//  of this view controller's view.
// -------------------------------------------------------------------------------
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.urlField.selectedRange = NSMakeRange(0, 0);
}

// -------------------------------------------------------------------------------
//	urlFieldWasTapped:
//  IBAction for the tap gesture recognizer defined in this view controller's
//  scene in the storyboard.  Selects the text displayed in the urlField.
// -------------------------------------------------------------------------------
- (IBAction)urlFieldWasTapped:(id)sender
{
    [self.urlField selectAll:self];
}

// -------------------------------------------------------------------------------
//	sliderValueDidChange:
//  IBAction for all three sliders.
// -------------------------------------------------------------------------------
- (IBAction)sliderValueDidChange:(id)sender
{
    // Create a new UIColor object with the current value of all three sliders
    // (it does not matter which one was actualy modified).  Assign it
    // as the new selectedColor.  The override of the setter for selectedColor
    // will handle updating the UI.
    self.selectedColor = [UIColor colorWithRed:self.redSlider.value
                                         green:self.greenSlider.value
                                          blue:self.blueSlider.value
                                         alpha:1.0f];
}

// -------------------------------------------------------------------------------
//	startMobileSafari:
//  IBAction for the Launch Mobile Safari button.
// -------------------------------------------------------------------------------
- (IBAction)startMobileSafari:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.apple.com"]];
}

@end
