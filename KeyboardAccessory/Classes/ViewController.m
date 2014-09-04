/*
     File: ViewController.m
 Abstract: View controller that adds a keyboard accessory to a text view.
 
  Version: 1.5
 
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

@interface ViewController () <UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIView *accessoryView; // view placed on top of keyboard

@property (nonatomic, weak) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *doneButton;

// the height constraint we want to change when the keyboard shows/hides
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintToAdjust;

@end


#pragma mark -

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // set the right bar button item initially to "Edit" state
    self.navigationItem.rightBarButtonItem = self.editButton;
}

- (void)viewDidAppear:(BOOL)animated {
    
    // observe keyboard hide and show notifications to resize the text view appropriately
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // start editing the UITextView (makes the keyboard appear when the application launches)
    [self editAction:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self adjustSelection:self.textView];
}


#pragma mark - Actions

- (IBAction)doneAction:(id)sender {
    
    // user tapped the Done button, release first responder on the text view
    [self.textView resignFirstResponder];
}

- (IBAction)editAction:(id)sender {
    
    // user tapped the Edit button, make the text view first responder
    [self.textView becomeFirstResponder];
}


#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)aTextView {
    
    // note: you can create the accessory view programmatically (in code), or from the storyboard
    if (self.textView.inputAccessoryView == nil) {
        
        self.textView.inputAccessoryView = self.accessoryView;  // use what's in the storyboard
    }
    
    self.navigationItem.rightBarButtonItem = self.doneButton;
    
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)aTextView {
    
    [aTextView resignFirstResponder];
    self.navigationItem.rightBarButtonItem = self.editButton;
    
    return YES;
}

- (void)adjustSelection:(UITextView *)textView {
    
    // workaround to UITextView bug, text at the very bottom is slightly cropped by the keyboard
    if ([textView respondsToSelector:@selector(textContainerInset)]) {
        [textView layoutIfNeeded];
        CGRect caretRect = [textView caretRectForPosition:textView.selectedTextRange.end];
        caretRect.size.height += textView.textContainerInset.bottom;
        [textView scrollRectToVisible:caretRect animated:NO];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    
    [self adjustSelection:textView];
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    
    [self adjustSelection:textView];
}


#pragma mark - Responding to keyboard events

- (void)adjustTextViewByKeyboardState:(BOOL)showKeyboard keyboardInfo:(NSDictionary *)info {
    
    /*
     Reduce the size of the text view so that it's not obscured by the keyboard.
     Animate the resize so that it's in sync with the appearance of the keyboard.
     */
    
    // transform the UIViewAnimationCurve to a UIViewAnimationOptions mask
    UIViewAnimationCurve animationCurve = [info[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions animationOptions = UIViewAnimationOptionBeginFromCurrentState;
    if (animationCurve == UIViewAnimationCurveEaseIn) {
        animationOptions |= UIViewAnimationOptionCurveEaseIn;
    }
    else if (animationCurve == UIViewAnimationCurveEaseInOut) {
        animationOptions |= UIViewAnimationOptionCurveEaseInOut;
    }
    else if (animationCurve == UIViewAnimationCurveEaseOut) {
        animationOptions |= UIViewAnimationOptionCurveEaseOut;
    }
    else if (animationCurve == UIViewAnimationCurveLinear) {
        animationOptions |= UIViewAnimationOptionCurveLinear;
    }
    
    [self.textView setNeedsUpdateConstraints];
    
    if (showKeyboard) {
        UIDeviceOrientation orientation = self.interfaceOrientation;
        BOOL isPortrait = UIDeviceOrientationIsPortrait(orientation);
        
        NSValue *keyboardFrameVal = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
        CGRect keyboardFrame = [keyboardFrameVal CGRectValue];
        CGFloat height = isPortrait ? keyboardFrame.size.height : keyboardFrame.size.width;
        
        // adjust the constraint constant to include the keyboard's height
        self.constraintToAdjust.constant += height;
    }
    else {
        self.constraintToAdjust.constant = 0;
    }

    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [UIView animateWithDuration:animationDuration delay:0 options:animationOptions animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];

    // now that the frame has changed, move to the selection or point of edit
    NSRange selectedRange = self.textView.selectedRange;
    [self.textView scrollRangeToVisible:selectedRange];
}

- (void)keyboardWillShow:(NSNotification *)notification {

    /*
     Reduce the size of the text view so that it's not obscured by the keyboard.
     Animate the resize so that it's in sync with the appearance of the keyboard.
     */
    
    NSDictionary *userInfo = [notification userInfo];
    [self adjustTextViewByKeyboardState:YES keyboardInfo:userInfo];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    
    /*
     Restore the size of the text view (fill self's view).
     Animate the resize so that it's in sync with the disappearance of the keyboard.
     */
    
    NSDictionary *userInfo = [notification userInfo];
    [self adjustTextViewByKeyboardState:NO keyboardInfo:userInfo];
}


#pragma mark - Accessory view action

- (IBAction)tappedMe:(id)sender {
    
    // when the accessory view button is tapped, add a suitable string to the text view
    NSMutableString *text = [self.textView.text mutableCopy];
    NSRange selectedRange = self.textView.selectedRange;
    
    [text replaceCharactersInRange:selectedRange withString:@"\nYou tapped me."];
    self.textView.text = text;
    
    [self adjustSelection:sender];
}

@end
