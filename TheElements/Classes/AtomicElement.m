/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Simple object that encapsulate the Atomic Element values and images for the states.
*/


#import "AtomicElement.h"

@interface AtomicElement ()

@property (nonatomic, strong) NSNumber *vertPos;
@property (nonatomic, strong) NSNumber *horizPos;
@property (readonly) CGPoint positionForElement;
@property  BOOL radioactive;

@end

@implementation AtomicElement

- (instancetype)initWithDictionary:(NSDictionary *)aDictionary {
    
	self = [[AtomicElement alloc] init];
    if (self) {
		self.atomicNumber = [aDictionary valueForKey:@"atomicNumber"];
		self.atomicWeight = [aDictionary valueForKey:@"atomicWeight"];
		self.discoveryYear = [aDictionary valueForKey:@"discoveryYear"];
		self.radioactive = [[aDictionary valueForKey:@"radioactive"] boolValue];
		self.name = [aDictionary valueForKey:@"name"];
		self.symbol = [aDictionary valueForKey:@"symbol"];
		self.state = [aDictionary valueForKey:@"state"];
		self.group = [aDictionary valueForKey:@"group"];
		self.period = [aDictionary valueForKey:@"period"];
		self.vertPos = [aDictionary valueForKey:@"vertPos"];
		self.horizPos = [aDictionary valueForKey:@"horizPos"];
	}
	return self;
}

 
// this returns the position of the element in the classic periodic table locations
- (CGPoint)positionForElement {
    
	return CGPointMake([[self horizPos] intValue] * 26-8, [[self vertPos] intValue]*26+35);
}

- (UIImage *)stateImageForAtomicElementTileView {
    
	return [UIImage imageNamed:[NSString stringWithFormat:@"%@_37.png", self.state]];
}

- (UIImage *)stateImageForAtomicElementView {
	return [UIImage imageNamed:[NSString stringWithFormat:@"%@_256.png", self.state]];
}

- (UIImage *)stateImageForPeriodicTableView {
	return [UIImage imageNamed:[NSString stringWithFormat:@"%@_24.png", self.state]];
}

- (UIImage *)flipperImageForAtomicElementNavigationItem {
	
	// return a 30 x 30 image that is a reduced version
	// of the AtomicElementTileView content
	// this is used to display the flipper button in the navigation bar
	CGSize itemSize = CGSizeMake(30.0,30.0);
	UIGraphicsBeginImageContext(itemSize);
	
	UIImage *backgroundImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_30.png", self.state]];
	CGRect elementSymbolRectangle = CGRectMake(0, 0, itemSize.width, itemSize.height);
	[backgroundImage drawInRect:elementSymbolRectangle];

	// draw the element name
	[[UIColor whiteColor] set];
	
	// draw the element number
    NSDictionary *font = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:8]};
	CGPoint point = CGPointMake(2,1);
	[[self.atomicNumber stringValue] drawAtPoint:point withAttributes:font];
	
	// draw the element symbol
	font = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:13]};
    CGSize stringSize = [self.symbol sizeWithAttributes:font];
	point = CGPointMake((elementSymbolRectangle.size.width-stringSize.width)/2,10);
	
	[self.symbol drawAtPoint:point withAttributes:font];
	
	UIImage *theImage=UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return theImage;
}

@end
