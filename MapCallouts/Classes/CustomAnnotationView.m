/*
     File: CustomAnnotationView.m
 Abstract: The custom MKAnnotationView object representing a generic location, displaying a title and image.
  Version: 1.4
 
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

#import "CustomAnnotationView.h"
#import "CustomMapItem.h"

static CGFloat kMaxViewWidth = 150.0;

static CGFloat kViewWidth = 90;
static CGFloat kViewLength = 100;

static CGFloat kLeftMargin = 15.0;
static CGFloat kRightMargin = 5.0;
static CGFloat kTopMargin = 5.0;
static CGFloat kBottomMargin = 10.0;
static CGFloat kRoundBoxLeft = 10.0;

@interface CustomAnnotationView ()
@property (nonatomic, strong) UILabel *annotationLabel;
@property (nonatomic, strong) UIImageView *annotationImage;
@end

@implementation CustomAnnotationView

// determine the MKAnnotationView based on the annotation info and reuseIdentifier
//
- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self != nil)
    {
        self.backgroundColor = [UIColor clearColor];
        
        // offset the annotation so it won't obscure the actual lat/long location
        self.centerOffset = CGPointMake(50.0, 50.0);
        
        // add the annotation's label
        _annotationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        CustomMapItem *mapItem = (CustomMapItem *)self.annotation;
        self.annotationLabel.font = [UIFont systemFontOfSize:9.0];
        self.annotationLabel.textColor = [UIColor whiteColor];
        self.annotationLabel.text = mapItem.place;
        [self.annotationLabel sizeToFit];   // get the right vertical size

        // compute the optimum width of our annotation, based on the size of our annotation label
        CGFloat optimumWidth = self.annotationLabel.frame.size.width + kRightMargin + kLeftMargin;
        CGRect frame = self.frame;
        if (optimumWidth < kViewWidth)
            frame.size = CGSizeMake(kViewWidth, kViewLength);
        else if (optimumWidth > kMaxViewWidth)
            frame.size = CGSizeMake(kMaxViewWidth, kViewLength);
        else
            frame.size = CGSizeMake(optimumWidth, kViewLength);
        self.frame = frame;
        
        self.annotationLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.annotationLabel.backgroundColor = [UIColor clearColor];
        CGRect newFrame = self.annotationLabel.frame;
        newFrame.origin.x = kLeftMargin;
        newFrame.origin.y = kTopMargin;
        newFrame.size.width = self.frame.size.width - kRightMargin - kLeftMargin;
        self.annotationLabel.frame = newFrame;
        [self addSubview:self.annotationLabel];
        
        // add the annotation's image
        // the annotation image snaps to the width and height of this view
        _annotationImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:mapItem.imageName]];
        self.annotationImage.contentMode = UIViewContentModeScaleAspectFit;
        self.annotationImage.frame =
            CGRectMake(kLeftMargin,
                       self.annotationLabel.frame.origin.y + self.annotationLabel.frame.size.height + kTopMargin,
                       self.frame.size.width - kRightMargin - kLeftMargin,
                       self.frame.size.height - self.annotationLabel.frame.size.height - kTopMargin*2 - kBottomMargin);
        [self addSubview:self.annotationImage];
    }
    
    return self;
}

- (void)setAnnotation:(id <MKAnnotation>)annotation
{
    [super setAnnotation:annotation];
    
    // this annotation view has custom drawing code.  So when we reuse an annotation view
    // (through MapView's delegate "dequeueReusableAnnoationViewWithIdentifier" which returns non-nil)
    // we need to have it redraw the new annotation data.
    //
    // for any other custom annotation view which has just contains a simple image, this won't be needed
    //
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CustomMapItem *mapItem = (CustomMapItem *)self.annotation;
    if (mapItem != nil)
    {
        [[UIColor darkGrayColor] setFill];
        
        // draw the pointed shape
        UIBezierPath *pointShape = [UIBezierPath bezierPath];
        [pointShape moveToPoint:CGPointMake(14.0, 0.0)];
        [pointShape addLineToPoint:CGPointMake(0.0, 0.0)];
        [pointShape addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
        [pointShape fill];
        
        // draw the rounded box
        UIBezierPath *roundedRect =
            [UIBezierPath bezierPathWithRoundedRect:
                CGRectMake(kRoundBoxLeft, 0.0, self.frame.size.width - kRoundBoxLeft, self.frame.size.height) cornerRadius:3.0];
        roundedRect.lineWidth = 2.0;
        [roundedRect fill];
    }
}

@end
