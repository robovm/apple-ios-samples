/*
     File: TapView.m
 Abstract: UIView subclass that can highlight itself when locally or remotely tapped.
  Version: 2.1
 
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

#import "TapView.h"

@import QuartzCore;

static const CGFloat kActivationInset = 10.0f;

@interface TapView ()

@property (nonatomic, assign, readwrite) BOOL   localTouch;

@end

@implementation TapView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    assert( ! self.isMultipleTouchEnabled );
    self.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    // Observe ourself to learn about someone changing the remoteTouch property.
    [self addObserver:self forKeyPath:@"remoteTouch" options:0 context:&self->_remoteTouch];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"remoteTouch" context:&self->_remoteTouch];
}

- (void)updateLayerBorder
{
    self.layer.borderWidth = (self.localTouch || self.remoteTouch) ? kActivationInset : 0.0f;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->_remoteTouch) {
        // If the remoteTouch property changes, redraw.
        [self updateLayerBorder];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)resetTouches
    // See comment in header.
{
    [self localTouchUpNotify:NO];
    if (self.remoteTouch) {
        self.remoteTouch = NO;
    }
}

#pragma mark - Touch tracking

- (void)localTouchDown
{
    if ( ! self.localTouch ) {
        id <TapViewDelegate>  strongDelegate;

        self.localTouch = YES;
        [self updateLayerBorder];

        strongDelegate = self.delegate;
        if ([strongDelegate respondsToSelector:@selector(tapViewLocalTouchDown:)]) {
            [strongDelegate tapViewLocalTouchDown:self];
        }
    }
}

- (void)localTouchUpNotify:(BOOL)notify
{
    if ( self.localTouch ) {
        self.localTouch = NO;
        [self updateLayerBorder];
        if (notify) {
            id <TapViewDelegate>  strongDelegate;

            strongDelegate = self.delegate;
            if ([strongDelegate respondsToSelector:@selector(tapViewLocalTouchUp:)]) {
                [strongDelegate tapViewLocalTouchUp:self];
            }
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    #pragma unused(touches)
    #pragma unused(event)
    [self localTouchDown];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    #pragma unused(touches)
    #pragma unused(event)
    [self localTouchUpNotify:YES];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    #pragma unused(touches)
    #pragma unused(event)
    [self localTouchUpNotify:YES];
}

@end
