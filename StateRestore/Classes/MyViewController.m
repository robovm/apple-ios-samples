/*
     File: MyViewController.m
 Abstract: The detail view controller for editing the title and notes of an item.
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "MyViewController.h"
#import "DataSource.h"
#import "Item.h"

static NSString *kUnsavedItemKey = @"unsavedItemKey";

#ifdef MANUALLY_CREATE_VC_FOR_RESTORATION
@interface MyViewController () <UIViewControllerRestoration>
#else
@interface MyViewController ()
#endif

@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;

// note that the UITextField and UITextView have restoration identifiers in the storyboard,
// which will help save their selection and scroll position
//
@property (nonatomic, weak) IBOutlet UITextField *editField;
@property (nonatomic, weak) IBOutlet UITextView *textView;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *saveButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *cancelButton;

@end


#pragma mark -

@implementation MyViewController

- (void)awakeFromNib
{
    // note: usually we set the restoration identifier in the storyboard, but if you want
    // to do it in code, do it here
    //
#ifdef MANUALLY_CREATE_VC_FOR_RESTORATION
    self.restorationClass = [self class];
#endif
}

- (void)setupWithItem
{
    if (self.item)
    {
        self.editField.text = self.item.title;
        self.textView.text = self.item.notes;
        self.navigationBar.topItem.title = self.item.title;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // listen for keyboard hide/show notifications so we can properly adjust the table's height
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editFieldChanged:) name:UITextFieldTextDidChangeNotification object:self.editField];
    
    [self.textView becomeFirstResponder];  // we want the keyboard up when this view appears
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
	
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidChangeNotification
                                                  object:self.editField];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupWithItem];
}

// since we are the primary view controller, we need these 2 rotating methods:
- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


#pragma mark - UIStateRestoration

// this is called when the app is suspended to the background
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSLog(@"MyViewController: encodeRestorableStateWithCoder");
    
    [super encodeRestorableStateWithCoder:coder];
    
    // save off any recent changes first since we are about to be suspended
    self.item.notes = self.textView.text;
    self.item.title = self.editField.text;
    
    [[DataSource sharedInstance] save];
    
    // encode only its UUID (identifier), and later we get back the item by searching for its UUID
    [coder encodeObject:self.item.identifier forKey:kUnsavedItemKey];
}

// this is called when the app is re-launched
- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    // important: don't affect our views just yet, we might not visible or we aren't the current
    // view controller, save off our ivars and restore our text view in viewWillAppear
    //
    NSLog(@"MyViewController: decodeRestorableStateWithCoder");
    
    [super decodeRestorableStateWithCoder:coder];
    
    // decode the edited item
    if ([coder containsValueForKey:kUnsavedItemKey])
    {
        // unarchive the UUID (identifier) and search for the item by its UUID
        NSString *identifier = [coder decodeObjectForKey:kUnsavedItemKey];
        self.item = [[DataSource sharedInstance] itemWithIdentifier:identifier];
        [self setupWithItem];
    }
}


#pragma mark - UIViewControllerRestoration

#ifdef MANUALLY_CREATE_VC_FOR_RESTORATION
+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents
                                                            coder:(NSCoder *)coder
{
    NSLog(@"MyViewController: viewControllerWithRestorationIdentifierPath called for %@", identifierComponents);
    
    MyViewController *vc = nil;
    
    // get our main storyboard to obtain our view controller
    UIStoryboard *storyboard = [coder decodeObjectForKey:UIStateRestorationViewControllerStoryboardKey];
    if (storyboard)
    {
        vc = (MyViewController *)[storyboard instantiateViewControllerWithIdentifier:@"viewController"];
        vc.restorationIdentifier = [identifierComponents lastObject];
        vc.restorationClass = [MyViewController class];
    }
    return vc;
}
#endif


#pragma mark - Actions

- (IBAction)saveAction:(id)sender
{
    // user tapped the Save button, save the contents
    //
    [self dismissViewControllerAnimated:YES completion:^{
            
        self.item.notes = self.textView.text;
        self.item.title = self.editField.text;
        
        [self.delegate editHasEnded:self withItem:self.item];
    }];
}

- (IBAction)cancelAction:(id)sender
{
    // user tapped the Cancel button, don't save
    //
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Keyboard support

- (void)adjustViewForKeyboardReveal:(BOOL)showKeyboard notificationInfo:(NSDictionary *)notificationInfo
{
    // the keyboard is showing so resize the text view's height
	CGRect keyboardRect = [[notificationInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration =
    [[notificationInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect frame = self.textView.frame;
    
    // note the keyboard rect's width and height are reversed in landscape
    NSInteger adjustDelta =
    UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? CGRectGetHeight(keyboardRect) : keyboardRect.size.width;
    
    if (showKeyboard)
        frame.size.height -= adjustDelta;
    else
        frame.size.height += adjustDelta;
    
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    self.textView.frame = frame;
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)aNotification
{
	[self adjustViewForKeyboardReveal:YES notificationInfo:[aNotification userInfo]];
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    [self adjustViewForKeyboardReveal:NO notificationInfo:[aNotification userInfo]];
}

- (void)editFieldChanged:(NSNotification *)notif
{
    // disable the Save button if there is no text for the title
    UITextField *textField = [notif object];
    self.saveButton.enabled = textField.text.length > 0;
}

@end

