/*
     File: AtomicElement.m
 Abstract: Simple object that encapsulate the Atomic Element values and images for the states.
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

#import "AtomicElement.h"

@interface AtomicElement ()

@property (nonatomic, strong) NSNumber *vertPos;
@property (nonatomic, strong) NSNumber *horizPos;
@property (readonly) CGPoint positionForElement;
@property  BOOL radioactive;

@end

@implementation AtomicElement

- (id)initWithDictionary:(NSDictionary *)aDictionary {
    
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
	UIFont *font = [UIFont boldSystemFontOfSize:8];
	CGPoint point = CGPointMake(2,1);
	[[self.atomicNumber stringValue] drawAtPoint:point withFont:font];
	
	// draw the element symbol
	font = [UIFont boldSystemFontOfSize:13];
	CGSize stringSize = [self.symbol sizeWithFont:font];
	point = CGPointMake((elementSymbolRectangle.size.width-stringSize.width)/2,10);
	
	[self.symbol drawAtPoint:point withFont:font];
	
	UIImage *theImage=UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return theImage;
}

@end
