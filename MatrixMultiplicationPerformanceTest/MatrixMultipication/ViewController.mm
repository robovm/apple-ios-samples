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
    uint32_t                mnPercentage;
    float                   mnProgress;
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
        
        // Percentage multiplier
        mnPercentage = 100 / mnCount;
        
        // Progress bar multiplier
        mnProgress = 1.0f / float(mnCount);
        
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

- (void) _updateResults:(NSDictionary *)pUserInfo
{
    NSString* pText = [[NSString alloc] initWithFormat:@"%@\n%@\n\n",
                       pUserInfo[kMatrixLogDimensions],
                       pUserInfo[kMatrixLogPerformance]];
    
    if(pText)
    {
        [self _displayText:pText];
    } // if
} // _updateResults

- (void) _updateColor:(const uint32_t)tid
{
    UIColor* pColor = nil;
    
    const uint32_t percent = tid * mnPercentage;
    
    if(percent <= 35)
    {
        pColor = [UIColor redColor];
    } // if
    else if((percent > 35) && (percent <= 70))
    {
        pColor = [UIColor yellowColor];
    } // else if
    else if(percent > 70)
    {
        pColor = [UIColor greenColor];
    } // else
    
    if(pColor)
    {
        _percent.textColor          = pColor;
        _count.textColor            = pColor;
        _progress.progressTintColor = pColor;
    } // if
} // _updateColor

- (void) _updateProgress:(const uint32_t)nTID
{
    _count.text        = [NSString stringWithFormat:@"Test %u Completed", nTID];
    _percent.text      = [NSString stringWithFormat:@"%d %%", nTID * mnPercentage];
    _progress.progress = mnProgress * float(nTID);
} // _updateProgress

- (void) _receiveIsReadyLogDataNotification:(NSNotification *) notification
{
    if([[notification name] isEqualToString:kMatrixNotificationIsReadyLogData])
    {
        NSDictionary* pUserInfo = notification.userInfo;
        
        if(pUserInfo)
        {
            const uint32_t nTID = [pUserInfo[kMatrixLogTestID] unsignedIntValue];
            
            if(nTID <= mnCount)
            {
                // Dispatch to update the UI
                dispatch_async(m_DQueue, ^{
                    [self _updateResults:pUserInfo];
                    [self _updateColor:nTID];
                    [self _updateProgress:nTID];
                });
            } // if
        } // if
    } // if
} // _receiveIsReadyLogDataNotification

- (void) _receiveIsDoneNotification:(NSNotification *) notification
{
    if([[notification name] isEqualToString:kMatrixNotificationIsDoneTests])
    {
        dispatch_barrier_sync(m_DQueue, ^{
            [self _displayText:@"\n>> Matrix multiplication tests are complete!\n\n"];
        });
    } // if
} // _receiveIsDoneNotification

- (void) _prepareMainQueue
{
    // Get the main dispatch queue  which is a globally available serial queue
    // that executes tasks on the application’s main thread.
    static dispatch_once_t token = 0;
    
    dispatch_once(&token, ^{
        m_DQueue = dispatch_get_main_queue();
    });
} // _prepareMainQueue

- (void) _prepareObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_receiveIsReadyLogDataNotification:)
                                                 name:kMatrixNotificationIsReadyLogData
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_receiveIsDoneNotification:)
                                                 name:kMatrixNotificationIsDoneTests
                                               object:nil];
} // _prepareObservers

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
    
    [self _prepareMainQueue];
    [self _prepareObservers];
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
