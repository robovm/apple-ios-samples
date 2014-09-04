/*
     File: ViewController.m
 Abstract: n/a
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "ViewController.h"

#define DefaultFontSize 48
#define PaddingFactor 0.1f

@interface ViewController ()

@end

@implementation ViewController

 /* Return a font based on what the user selected */
-(UIFont *)chosenFontWithSize:(CGFloat)fontSize;
{
    UIFont *font = nil;
    switch (self.fontSelection.selectedSegmentIndex) {
        case 0:
            font = [UIFont fontWithName:@"American Typewriter" size:fontSize];
            break;
        case 1:
            font = [UIFont fontWithName:@"Snell Roundhand" size:fontSize];
            break;
        case 2:
            font = [UIFont fontWithName:@"Courier" size:fontSize];
            break;
        default:
            font = [UIFont fontWithName:@"Arial" size:fontSize];
            break;
    }
    if (font == nil)
        font = [UIFont systemFontOfSize:fontSize];

    return font;
}

 /* Return a color based on what the user selected */
- (UIColor *)chosenColor;
{
    UIColor *color;
    switch (self.colorSelection.selectedSegmentIndex) {
        case 0:
            color = [UIColor blackColor];
            break;
        case 1:
            color = [UIColor orangeColor];
            break;
        case 2:
            color = [UIColor purpleColor];
            break;
        default:
            color = [UIColor redColor];;
            break;
    }
    return color;
}

 /* Dismiss the keyboard when the user taps off the text field */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
    [self.textField resignFirstResponder];
}

-(IBAction)print:(id)sender;
{
    /* Get the UIPrintInteractionController, which is a shared object */
    UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
	if(!controller){
		NSLog(@"Couldn't get shared UIPrintInteractionController!");
		return;
	}
    
    /* Set this object as delegate so you can  use the printInteractionController:cutLengthForPaper: delegate */
    controller.delegate = self;
		
	UIPrintInfo *printInfo = [UIPrintInfo printInfo];
	printInfo.outputType = UIPrintInfoOutputGeneral;

    /* Use landscape orientation for a banner so the text  print along the long side of the paper. */
    printInfo.orientation = UIPrintInfoOrientationLandscape;

	printInfo.jobName = self.textField.text;
	controller.printInfo = printInfo;
    
    /* Create the UISimpleTextPrintFormatter with the text supplied by the user in the text field */
    _textFormatter = [[UISimpleTextPrintFormatter alloc] initWithText:self.textField.text];
    
    /* Set the text formatter's color and font properties based on what the user chose */
    _textFormatter.color = [self chosenColor];
    _textFormatter.font = [self chosenFontWithSize:DefaultFontSize];
    
    /* Set this UISimpleTextPrintFormatter on the controller */
    controller.printFormatter = _textFormatter;
    
    /* Set up a completion handler block.  If the print job has an error before spooling, this is where it's handled. */
	void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) = ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        if(completed && error)
            NSLog( @"Printing failed due to error in domain %@ with error code %lu. Localized description: %@, and failure reason: %@", error.domain, (long)error.code, error.localizedDescription, error.localizedFailureReason );
	};

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[controller presentFromRect:self.printButton.frame inView:self.view animated:YES completionHandler:completionHandler];
	else
		[controller presentAnimated:YES completionHandler:completionHandler];  // iPhone
}

- (CGFloat)printInteractionController:(UIPrintInteractionController *)printInteractionController cutLengthForPaper:(UIPrintPaper *)paper {

    /* Create a font with arbitrary size so that you can calculate the approximate
        font points per screen point for the height of the text. */
    UIFont *font = _textFormatter.font;
    CGSize size = [self.textField.text sizeWithAttributes:@{NSFontAttributeName: font}];
    
    float approximateFontPointPerScreenPoint = font.pointSize / size.height;
    
    /* Create a new font using a size  that will fill the width of the paper */
    font = [self chosenFontWithSize: paper.printableRect.size.width * approximateFontPointPerScreenPoint];
    
    /* Calculate the height and width of the text with the final font size */
    CGSize finalTextSize = [self.textField.text sizeWithAttributes:@{NSFontAttributeName: font}];
    
    /* Set the UISimpleTextFormatter font to the font with the size calculated */
    _textFormatter.font = font;
    
    /* Calculate the margins of the roll. Roll printers may have unprintable areas
        before and after the cut.  We must add this to our cut length to ensure the
        printable area has enough room for our text. */
    CGFloat lengthOfMargins = paper.paperSize.height - paper.printableRect.size.height;

    /* The cut length is the width of the text, plus margins, plus some padding */
    return finalTextSize.width + lengthOfMargins + paper.printableRect.size.width * PaddingFactor;
}


@end
