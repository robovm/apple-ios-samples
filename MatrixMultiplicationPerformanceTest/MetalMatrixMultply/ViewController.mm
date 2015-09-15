/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 View Controller
 */

#import <Foundation/Foundation.h>

#import "MatrixMultPTScheduler.h"
#import "ViewController.h"

@implementation ViewController
{
@private
    uint32_t                mnCount;
    dispatch_queue_t        m_DQueue;
    MatrixMultPTScheduler*  mpScheduler;
}

- (void) _dispatchTests
{
    // Instantiate a matrix multipication mediator performance test object
    mpScheduler = [MatrixMultPTScheduler new];
    
    if(mpScheduler)
    {
        // Log the test results
        mpScheduler.print = YES;
        
        // Total number of tests
        mnCount = mpScheduler.tests;
        
        // Display a message in the text view
        _texts.text = @">> Matrix multiplication tests are about to begin...\n\n";
        
        // Dispatch to excute all the matrix multipication performance tests
        [mpScheduler dispatch];
    } // if
    else
    {
        // Display error message in the text view
        _texts.text = @"\n\n>> ERROR: Failed to instantiate a test object!";
    } // else
    
} // _dispatchTests

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self _dispatchTests];
} // viewDidAppear

- (void) _displayText:(NSString *)pText
{
    const NSUInteger length = _texts.text.length;
    const NSRange    range  = NSMakeRange(length, 0);
    
    _texts.text = [_texts.text stringByAppendingString:pText];
    
    [_texts scrollRangeToVisible:range];
} // _displayText

- (void) _receiveIsReadyLogDataNotification:(NSNotification *) notification
{
    if([[notification name] isEqualToString:kMatrixNotificationIsReadyLogData])
    {
        NSDictionary *pUserInfo = notification.userInfo;
        
        if(pUserInfo)
        {
            const uint32_t nTID = [pUserInfo[kMatrixLogTestID] unsignedIntValue];
            
            if(nTID <= mnCount)
            {
                // UI block
                dispatch_block_t block = ^{
                    NSString* pText = [[NSString alloc] initWithFormat:@"%@\n%@\n\n",
                                       pUserInfo[kMatrixLogDimensions],
                                       pUserInfo[kMatrixLogPerformance]];
                    
                    if(pText)
                    {
                        [self _displayText:pText];
                    } // if
                };
                
                // Dispatch to update the UI
                dispatch_async(m_DQueue, block);
            } // if
        } // if
    } // if
} // _receiveIsReadyLogDataNotification

- (void) _receiveIsDoneNotification:(NSNotification *) notification
{
    if([[notification name] isEqualToString:kMatrixNotificationIsDoneTests])
    {
        dispatch_block_t block =  ^{
            [self _displayText:@"\n>> Matrix multiplication tests are complete!\n\n"];
        };
        
        dispatch_barrier_sync(m_DQueue, block);
    } // if
} // _receiveIsDoneNotification

- (void) _addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_receiveIsReadyLogDataNotification:)
                                                 name:kMatrixNotificationIsReadyLogData
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_receiveIsDoneNotification:)
                                                 name:kMatrixNotificationIsDoneTests
                                               object:nil];
} // _addObservers

- (void) _newQueue
{
    static dispatch_once_t token = 0;
    
    dispatch_once(&token, ^{
        m_DQueue = dispatch_get_main_queue();
    });
} // _newQueue

- (void) _prepareTextView
{
    _texts.delegate        = self;
    _texts.scrollEnabled   = YES;
    _texts.returnKeyType   = UIReturnKeyDone;
    _texts.backgroundColor = [UIColor blackColor];
    _texts.textColor       = [UIColor greenColor];
    _texts.font            = [UIFont fontWithName:@"Courier" size:12.0f];
} // _prepareTextView

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self _addObservers];
    [self _newQueue];
    [self _prepareTextView];
} // viewDidLoad

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
} // didReceiveMemoryWarning

- (void) dealloc
{
    // If self isn't removed as an observer, the Notification Center
    // will continue sending notification objects to the deallocated
    // object.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
} // dealloc

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
} // preferredStatusBarStyle

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
} // shouldAutorotateToInterfaceOrientation

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    [textView resignFirstResponder];

    return NO;
} // textViewShouldBeginEditing

- (BOOL) textViewShouldEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];

    return NO;
} // textViewShouldEndEditing

- (BOOL)        textView:(UITextView *)textView
 shouldChangeTextInRange:(NSRange)range
         replacementText:(NSString *)text
{
    [textView resignFirstResponder];
    
    return NO;
} // textView

- (void) touchesBegan:(NSSet *)touches
            withEvent:(UIEvent *)event
{
    for(UITextView* textView in self.view.subviews)
    {
        if([textView isFirstResponder])
        {
            [textView resignFirstResponder];
        } // if
    } // for
    
    [super touchesBegan:touches
              withEvent:event];
} // touchesBegan

@end
