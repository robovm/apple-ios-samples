/*
 File: APLTitleView.m
 Abstract: The title view of the sample map.
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

#import "APLTitleView.h"
#import "APLCommon.h"

@interface APLTitleView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation APLTitleView

#pragma mark - UIView overrides

// Custom drawing method to draw the indicators
//
- (void)drawRect:(CGRect)rect
{
    for ( NSInteger i = kMinimumFloor; i <= kMaximumFloor; ++i )
    {
        BOOL indicatorHighlighted = [self indicatorHighlightedForFloor:i];
        CGRect indicatorRect = [self indicatorRectForFloor:i];
        NSString *indicatorString = [NSString stringWithFormat:@"%ld", (long)i];
        
        // Draw indicator
        NSAttributedString *indicatorAttributedString = [[NSAttributedString alloc] initWithString:indicatorString attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:kFontSize], NSForegroundColorAttributeName : ( indicatorHighlighted ) ? [UIColor blackColor] : [UIColor lightGrayColor] }];
        UIBezierPath *indicatorBezierPath = [UIBezierPath bezierPathWithOvalInRect:indicatorRect];
        indicatorBezierPath.lineWidth = kLineWidth;
        [[UIColor whiteColor] setFill];
        [indicatorBezierPath fill];
        [( indicatorHighlighted ) ? [UIColor blackColor] : [UIColor lightGrayColor] setStroke];
        [indicatorBezierPath stroke];
        [indicatorAttributedString drawAtPoint:CGPointMake(CGRectGetMidX(indicatorRect) - indicatorAttributedString.size.width * 0.5, CGRectGetMidY(indicatorRect) - indicatorAttributedString.size.height * 0.5)];
    }
}

#pragma mark - UIAccessibilityElement

// Override to supply the accessibility attirbute value programmatically.
// The is the way to supply dynamic value for accessibility attribute.
// For static attribute value, we can also set up within Xcode (Interface Builder).

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.titleLabel.text;
}

// Supply the accessibility value based on the floor
//
- (NSString *)accessibilityValue
{
    // Return a formatted number string
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    return [numberFormatter stringFromNumber:[NSNumber numberWithInteger:self.floor]];
}


#pragma mark - Helpers

// Return indicator hightlighted status for specified floor
//
- (BOOL)indicatorHighlightedForFloor:(NSInteger)floor
{
    return floor == self.floor;
}

// Return indicator rectangle for specified floor
//
- (CGRect)indicatorRectForFloor:(NSInteger)floor
{
    CGRect bounds = self.bounds;
    CGFloat indicatorWidth = CGRectGetHeight(bounds) - kPadding * 2.0;
    
    switch ( floor )
    {
        case 1:
            return CGRectMake(CGRectGetMidX(bounds) + CGRectGetWidth(bounds) * 0.25 - indicatorWidth * 1.5 - kPadding * 2.0, kPadding, indicatorWidth, indicatorWidth);
        case 2:
            return CGRectMake(CGRectGetMidX(bounds) + CGRectGetWidth(bounds) * 0.25 - indicatorWidth * 0.5, kPadding, indicatorWidth, indicatorWidth);
        case 3:
            return CGRectMake(CGRectGetMidX(bounds) + CGRectGetWidth(bounds) * 0.25 + indicatorWidth * 0.5 + kPadding * 2.0, kPadding, indicatorWidth, indicatorWidth);
        default:
            // Unsupported floor
            return CGRectZero;
    }
}

#pragma mark - Properties

// floop properrt setter, make sure the floor values is between [kMinimumFloor, kMaximumFloor]
//
- (void)setFloor:(NSInteger)floor
{
    // Clamp floor between [kMinimumFloor, kMaximumFloor]
    _floor = MAX(MIN(floor, kMaximumFloor), kMinimumFloor);
    [self setNeedsDisplay];
}

@end
