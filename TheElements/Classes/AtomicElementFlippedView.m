/*
     File: AtomicElementFlippedView.m
 Abstract: Displays the Atomic Element information with a link to Wikipedia.
  Version: 1.12
 
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

#import "AtomicElementView.h"
#import "AtomicElement.h"
#import "AtomicElementFlippedView.h"

@interface AtomicElementFlippedView ()

@property (nonatomic,strong) UIButton *wikipediaButton;

@end

@implementation AtomicElementFlippedView


- (void)setupUserInterface {
    
	CGRect buttonFrame = CGRectMake(10.0, 209.0, 234.0, 37.0);
	
    // create the button
	self.wikipediaButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	self.wikipediaButton.frame=buttonFrame;
	
	[self.wikipediaButton setTitle:@"View at Wikipedia" forState:UIControlStateNormal];	
	
	// Center the text on the button, considering the button's shadow
	self.wikipediaButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	self.wikipediaButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	
	[self.wikipediaButton addTarget:self action:@selector(jumpToWikipedia:) forControlEvents:UIControlEventTouchUpInside];

	[self addSubview:self.wikipediaButton];
}

- (id)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
		[self setAutoresizesSubviews:YES];
		[self setupUserInterface];
		
		// set the background color of the view to clearn
		self.backgroundColor=[UIColor clearColor];
    }
    return self;
}

- (void)jumpToWikipedia:(id)sender {
    
	// create the string that points to the correct Wikipedia page for the element name
	NSString *wikiPageString = [NSString stringWithFormat:@"http://en.wikipedia.org/wiki/%@", self.element.name];
	if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:wikiPageString]])
	{
		// there was an error trying to open the URL. for the moment we'll simply ignore it.
	}
}

- (void)drawRect:(CGRect)rect {
	
	// get the background image for the state of the element
	// position it appropriately and draw the image
    //
	UIImage *backgroundImage = [self.element stateImageForAtomicElementView];
	CGRect elementSymbolRectangle = CGRectMake(0, 0, [backgroundImage size].width, [backgroundImage size].height);
	[backgroundImage drawInRect:elementSymbolRectangle];
	
	// all the text is drawn in white
	[[UIColor whiteColor] set];
	
	// draw the element number
	UIFont *font = [UIFont boldSystemFontOfSize:32];
	CGPoint point = CGPointMake(10,5);
	[[NSString stringWithFormat:@"%@", self.element.atomicNumber] drawAtPoint:point withFont:font];
	
	// draw the element symbol
	CGSize stringSize = [self.element.symbol sizeWithFont:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width-10),5);
	[self.element.symbol drawAtPoint:point withFont:font];
	
	// draw the element name
	font = [UIFont boldSystemFontOfSize:36];
	stringSize = [self.element.name sizeWithFont:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width)/2,50);
	[self.element.name drawAtPoint:point withFont:font];
	
	float verticalStartingPoint = 95;
	
	// draw the element weight
	font = [UIFont boldSystemFontOfSize:14];
	NSString *atomicWeightString = [NSString stringWithFormat:@"Atomic Weight: %@", self.element.atomicWeight];
	stringSize = [atomicWeightString sizeWithFont:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width)/2, verticalStartingPoint);
	[atomicWeightString drawAtPoint:point withFont:font];
	
	// draw the element state
	font = [UIFont boldSystemFontOfSize:14];
	NSString *stateString=[NSString stringWithFormat:@"State: %@", self.element.state];
	stringSize = [stateString sizeWithFont:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width)/2, verticalStartingPoint+20);
	[stateString drawAtPoint:point withFont:font];
	
	// draw the element period
	font = [UIFont boldSystemFontOfSize:14];
	NSString *periodString = [NSString stringWithFormat:@"Period: %@", self.element.period];
	stringSize = [periodString sizeWithFont:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width)/2, verticalStartingPoint+40);
	[periodString drawAtPoint:point withFont:font];

	// draw the element group
	font = [UIFont boldSystemFontOfSize:14];
	NSString *groupString = [NSString stringWithFormat:@"Group: %@", self.element.group];
	stringSize = [groupString sizeWithFont:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width)/2, verticalStartingPoint+60);
	[groupString drawAtPoint:point withFont:font];
	
	// draw the discovery year
	NSString *discoveryYearString = [NSString stringWithFormat:@"Discovered: %@", self.element.discoveryYear];
	stringSize = [discoveryYearString sizeWithFont:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width)/2, verticalStartingPoint+80);
	[discoveryYearString drawAtPoint:point withFont:font];
}


@end
