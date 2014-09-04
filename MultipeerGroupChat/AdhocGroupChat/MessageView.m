/*
     File: MessageView.m
 Abstract: 
    This is a content view class for managing the 'text message' type table view cells
 
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

#import "MessageView.h"
#import "Transcript.h"

// Constants for view sizing and alignment
#define MESSAGE_FONT_SIZE       (17.0)
#define NAME_FONT_SIZE          (10.0)
#define BUFFER_WHITE_SPACE      (14.0)
#define DETAIL_TEXT_LABEL_WIDTH (220.0)
#define NAME_OFFSET_ADJUST      (4.0)

#define BALLOON_INSET_TOP    (30 / 2)
#define BALLOON_INSET_LEFT   (36 / 2)
#define BALLOON_INSET_BOTTOM (30 / 2)
#define BALLOON_INSET_RIGHT  (46 / 2)

#define BALLOON_INSET_WIDTH (BALLOON_INSET_LEFT + BALLOON_INSET_RIGHT)
#define BALLOON_INSET_HEIGHT (BALLOON_INSET_TOP + BALLOON_INSET_BOTTOM)

#define BALLOON_MIDDLE_WIDTH (30 / 2)
#define BALLOON_MIDDLE_HEIGHT (6 / 2)

#define BALLOON_MIN_HEIGHT (BALLOON_INSET_HEIGHT + BALLOON_MIDDLE_HEIGHT)

#define BALLOON_HEIGHT_PADDING (10)
#define BALLOON_WIDTH_PADDING (30)

@interface MessageView ()

// Background image
@property (nonatomic, retain) UIImageView *balloonView;
// Message text string
@property (nonatomic, retain) UILabel *messageLabel;
// Name text (for received messages)
@property (nonatomic, retain) UILabel *nameLabel;
// Cache the background images and stretchable insets
@property (retain, nonatomic) UIImage *balloonImageLeft;
@property (retain, nonatomic) UIImage *balloonImageRight;
@property (assign, nonatomic) UIEdgeInsets balloonInsetsLeft;
@property (assign, nonatomic) UIEdgeInsets balloonInsetsRight;

@end

@implementation MessageView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        // Initialization the views
        _balloonView = [UIImageView new];
        _messageLabel = [UILabel new];
        _messageLabel.numberOfLines = 0;

        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:NAME_FONT_SIZE];
        _nameLabel.textColor = [UIColor colorWithRed:34.0/255.0 green:97.0/255.0 blue:221.0/255.0 alpha:1];

        self.balloonImageLeft = [UIImage imageNamed:@"bubble-left.png"];
        self.balloonImageRight = [UIImage imageNamed:@"bubble-right.png"];

        _balloonInsetsLeft = UIEdgeInsetsMake(BALLOON_INSET_TOP, BALLOON_INSET_RIGHT, BALLOON_INSET_BOTTOM, BALLOON_INSET_LEFT);
        _balloonInsetsRight = UIEdgeInsetsMake(BALLOON_INSET_TOP, BALLOON_INSET_LEFT, BALLOON_INSET_BOTTOM, BALLOON_INSET_RIGHT);

        // Add to parent view
        [self addSubview:_balloonView];
        [self addSubview:_messageLabel];
        [self addSubview:_nameLabel];
    }
    return self;
}

// Method for setting the transcript object which is used to build this view instance.
- (void)setTranscript:(Transcript *)transcript
{    
    // Set the message text
    NSString *messageText = transcript.message;
    _messageLabel.text = messageText;

    // Compute message size and frames
    CGSize labelSize = [MessageView labelSizeForString:messageText fontSize:MESSAGE_FONT_SIZE];
    CGSize balloonSize = [MessageView balloonSizeForLabelSize:labelSize];
    NSString *nameText = transcript.peerID.displayName;
    CGSize nameSize = [MessageView labelSizeForString:nameText fontSize:NAME_FONT_SIZE];

    // Comput the X,Y origin offsets
    CGFloat xOffsetLabel;
    CGFloat xOffsetBalloon;
    CGFloat yOffset;
    
    if (TRANSCRIPT_DIRECTION_SEND == transcript.direction) {
        // Sent messages appear or right of view
        xOffsetLabel = 320 - labelSize.width - (BALLOON_WIDTH_PADDING / 2) - 3;
        xOffsetBalloon = 320 - balloonSize.width;
        yOffset = BUFFER_WHITE_SPACE / 2;
        _nameLabel.text = @"";
        // Set text color
        _messageLabel.textColor = [UIColor whiteColor];
        // Set resizeable image
        _balloonView.image = [self.balloonImageRight resizableImageWithCapInsets:_balloonInsetsRight];
    }
    else {
        // Received messages appear on left of view with additional display name label
        xOffsetBalloon = 0;
        xOffsetLabel = (BALLOON_WIDTH_PADDING / 2) + 3;
        yOffset = (BUFFER_WHITE_SPACE / 2) + nameSize.height - NAME_OFFSET_ADJUST;
        if (TRANSCRIPT_DIRECTION_LOCAL == transcript.direction) {
            _nameLabel.text = @"Session Admin";
        }
        else {
            _nameLabel.text = nameText;
        }
        // Set text color
        _messageLabel.textColor = [UIColor darkTextColor];
        // Set resizeable image
        _balloonView.image = [self.balloonImageLeft resizableImageWithCapInsets:_balloonInsetsLeft];
    }

    // Set the dynamic frames
    _messageLabel.frame = CGRectMake(xOffsetLabel, yOffset + 5, labelSize.width, labelSize.height);
    _balloonView.frame = CGRectMake(xOffsetBalloon, yOffset, balloonSize.width, balloonSize.height);
    _nameLabel.frame = CGRectMake(xOffsetLabel - 2, 1, nameSize.width, nameSize.height);
}

#pragma - class methods for computing sizes based on strings

+ (CGFloat)viewHeightForTranscript:(Transcript *)transcript
{
    CGFloat labelHeight = [MessageView balloonSizeForLabelSize:[MessageView labelSizeForString:transcript.message fontSize:MESSAGE_FONT_SIZE]].height;
    if (TRANSCRIPT_DIRECTION_SEND != transcript.direction) {
        // Need to add extra height for display name
        CGFloat nameHeight = [MessageView labelSizeForString:transcript.peerID.displayName fontSize:NAME_FONT_SIZE].height;
        return (labelHeight + nameHeight + BUFFER_WHITE_SPACE - NAME_OFFSET_ADJUST);
    }
    else {
        return (labelHeight + BUFFER_WHITE_SPACE);
    }
}

+ (CGSize)labelSizeForString:(NSString *)string fontSize:(CGFloat)fontSize
{
    return [string boundingRectWithSize:CGSizeMake(DETAIL_TEXT_LABEL_WIDTH, 2000.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:fontSize]} context:nil].size;
}

+ (CGSize)balloonSizeForLabelSize:(CGSize)labelSize
{
 	CGSize balloonSize;

    if (labelSize.height < BALLOON_INSET_HEIGHT) {
        balloonSize.height = BALLOON_MIN_HEIGHT;
    }
    else {
        balloonSize.height = labelSize.height + BALLOON_HEIGHT_PADDING;
    }

    balloonSize.width = labelSize.width + BALLOON_WIDTH_PADDING;

    return balloonSize;
}

@end
