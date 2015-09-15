/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Displays the Atomic Element information with a link to Wikipedia.
*/

#import "AtomicElementFlippedView.h"
#import "AtomicElementView.h"
#import "AtomicElement.h"

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

- (instancetype)initWithFrame:(CGRect)frame {
    
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
	NSDictionary *font = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:32]};
	CGPoint point = CGPointMake(10,5);
	[[NSString stringWithFormat:@"%@", self.element.atomicNumber] drawAtPoint:point withAttributes:font];
	
	// draw the element symbol
	CGSize stringSize = [self.element.symbol sizeWithAttributes:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width-10),5);
	[self.element.symbol drawAtPoint:point withAttributes:font];
	
	// draw the element name
	font = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:36]};
	stringSize = [self.element.name sizeWithAttributes:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width)/2,50);
	[self.element.name drawAtPoint:point withAttributes:font];
	
	float verticalStartingPoint = 95;
	
	// draw the element weight
	font = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:14]};
	NSString *atomicWeightString = [NSString stringWithFormat:@"Atomic Weight: %@", self.element.atomicWeight];
	stringSize = [atomicWeightString sizeWithAttributes:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width)/2, verticalStartingPoint);
	[atomicWeightString drawAtPoint:point withAttributes:font];
	
	// draw the element state
	NSString *stateString=[NSString stringWithFormat:@"State: %@", self.element.state];
	stringSize = [stateString sizeWithAttributes:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width)/2, verticalStartingPoint+20);
	[stateString drawAtPoint:point withAttributes:font];
	
	// draw the element period
	NSString *periodString = [NSString stringWithFormat:@"Period: %@", self.element.period];
	stringSize = [periodString sizeWithAttributes:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width)/2, verticalStartingPoint+40);
	[periodString drawAtPoint:point withAttributes:font];

	// draw the element group
	NSString *groupString = [NSString stringWithFormat:@"Group: %@", self.element.group];
	stringSize = [groupString sizeWithAttributes:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width)/2, verticalStartingPoint+60);
	[groupString drawAtPoint:point withAttributes:font];
	
	// draw the discovery year
	NSString *discoveryYearString = [NSString stringWithFormat:@"Discovered: %@", self.element.discoveryYear];
	stringSize = [discoveryYearString sizeWithAttributes:font];
	point = CGPointMake((self.bounds.size.width-stringSize.width)/2, verticalStartingPoint+80);
	[discoveryYearString drawAtPoint:point withAttributes:font];
}


@end
