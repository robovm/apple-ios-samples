/*
     File: ProgressView.m
 Abstract: 
    This is a content view class for managing the 'resource progress' type table view cells
 
  Version: 1.0
 
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

@import MultipeerConnectivity;

#import "ProgressView.h"
#import "Transcript.h"
#import "ProgressObserver.h"

#define PROGRESS_VIEW_HEIGHT    (15.0)
#define PADDING_X               (15.0)
#define NAME_FONT_SIZE          (10.0)
#define BUFFER_WHITE_SPACE      (14.0)
#define PROGRESS_VIEW_WIDTH     (140.0)
#define PEER_NAME_HEIGHT        (12.0)
#define NAME_OFFSET_ADJUST      (4.0)

@interface ProgressView () <ProgressObserverDelegate>

// View for showing resource send/receive progress
@property UIProgressView *progressView;
// View for displaying sender name (received transcripts only)
@property UILabel *displayNameLabel;
// KVO progress observer for updating the progress bar based on NSProgress changes
@property ProgressObserver *observer;

@end

@implementation ProgressView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        // Initialization the sub views
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progress = 0.0;

        _displayNameLabel = [UILabel new];
        _displayNameLabel.font = [UIFont systemFontOfSize:10.0];
        _displayNameLabel.textColor = [UIColor colorWithRed:34.0/255.0 green:97.0/255.0 blue:221.0/255.0 alpha:1];

        // Add to parent view
        [self addSubview:_displayNameLabel];
        [self addSubview:_progressView];
    }
    return self;
}

// Method for setting the transcript object which is used to build this view instance.
- (void)setTranscript:(Transcript *)transcript
{
    // Create the progress observer
    self.observer = [[ProgressObserver alloc] initWithName:transcript.imageName progress:transcript.progress];
    // Listen for progress changes
    _observer.delegate = self;

    // Compute name size
    NSString *nameText = transcript.peerID.displayName;
    CGSize nameSize = [ProgressView labelSizeForString:nameText fontSize:NAME_FONT_SIZE];

    // Comput the X,Y origin offsets
    CGFloat xOffset;
    CGFloat yOffset;

    if (TRANSCRIPT_DIRECTION_SEND == transcript.direction) {
        // Sent images appear or right of view
        xOffset = 320 - PADDING_X - PROGRESS_VIEW_WIDTH;
        yOffset = BUFFER_WHITE_SPACE / 2;
        _displayNameLabel.text = @"";
    }
    else {
        // Received images appear on left of view with additional display name label
        xOffset = PADDING_X;
        yOffset = (BUFFER_WHITE_SPACE / 2) + nameSize.height - NAME_OFFSET_ADJUST;
        _displayNameLabel.text = nameText;
    }

    // Set the dynamic frames
    _displayNameLabel.frame = CGRectMake(xOffset, 1, nameSize.width, nameSize.height);
    _progressView.frame = CGRectMake(xOffset, yOffset + 5, PROGRESS_VIEW_WIDTH, PROGRESS_VIEW_HEIGHT);
}

#pragma - class methods for computing sizes based on strings

+ (CGFloat)viewHeightForTranscript:(Transcript *)transcript
{
    // Return dynamic height of the cell based on the particular transcript
    if (TRANSCRIPT_DIRECTION_RECEIVE == transcript.direction) {
        // The senders name height is included for received messages
        return (PEER_NAME_HEIGHT + PROGRESS_VIEW_HEIGHT + BUFFER_WHITE_SPACE - NAME_OFFSET_ADJUST);
    }
    else {
        // Just the scaled image height and some buffer space
        return (PROGRESS_VIEW_HEIGHT + BUFFER_WHITE_SPACE);
    }
}

+ (CGSize)labelSizeForString:(NSString *)string fontSize:(CGFloat)fontSize
{
    return [string boundingRectWithSize:CGSizeMake(PROGRESS_VIEW_WIDTH, 2000.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:fontSize]} context:nil].size;
}

#pragma mark - ProgressObserver delegate methods

- (void)observerDidChange:(ProgressObserver *)observer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Update the progress bar with the latest completion %
        _progressView.progress = observer.progress.fractionCompleted;
        NSLog(@"progress changed completedUnitCount[%lld]", observer.progress.completedUnitCount);
    });
}

- (void)observerDidCancel:(ProgressObserver *)observer
{
    NSLog(@"progress canceled");
}

- (void)observerDidComplete:(ProgressObserver *)observer
{
    NSLog(@"progress complete"); 
}

@end
